import Foundation

public struct MAMEError: LocalizedError, Sendable {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

/// Servicio de integración directa y segura con MAME en macOS
public final class MAMEIntegrationService: @unchecked Sendable {
    public static let shared = MAMEIntegrationService()
    
    // Rastreo de procesos de juegos actualmente en ejecución para evitar instancias duplicadas
    private var activeProcesses: [String: Process] = [:]
    private let processLock = NSLock()
    
    public init() {}
    
    // MARK: - Detección y Verificación del Ejecutable
    
    /// Comprueba si el ejecutable de MAME existe y tiene permisos de ejecución
    public func validateExecutablePath(_ path: String) -> (isValid: Bool, error: String?) {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue else {
            return (false, "El archivo ejecutable de MAME no existe en la ruta especificada.")
        }
        guard fm.isExecutableFile(atPath: path) else {
            return (false, "El archivo en la ruta no tiene permisos de ejecución.")
        }
        return (true, nil)
    }
    
    /// Detecta la versión de MAME ejecutando `mame -version`
    public func detectVersion(executablePath: String) async -> Result<String, Error> {
        let validation = validateExecutablePath(executablePath)
        guard validation.isValid else {
            return .failure(NSError(domain: "MAMEService", code: 1, userInfo: [NSLocalizedDescriptionKey: validation.error ?? "Ruta no válida"]))
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = ["-version"]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                
                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    
                    if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                        // El formato suele ser "0.289 (unknown)"
                        continuation.resume(returning: .success(output))
                    } else {
                        continuation.resume(returning: .failure(NSError(domain: "MAMEService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Salida vacía de MAME"])))
                    }
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    // MARK: - Consulta de Metadatos
    
    /// Consulta el nombre comercial y descripción rápida usando `-listfull`
    public func queryGameDescription(systemName: String, executablePath: String) async -> String? {
        guard sanitizeIdentifier(systemName) != nil else { return nil }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = ["-listfull", systemName]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                
                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    
                    if let output = String(data: data, encoding: .utf8) {
                        let lines = output.components(separatedBy: .newlines)
                        for line in lines {
                            let trimmed = line.trimmingCharacters(in: .whitespaces)
                            if trimmed.hasPrefix(systemName) {
                                // Formato: pacman           "Pac-Man (Midway)"
                                if let start = trimmed.firstIndex(of: "\""), let end = trimmed.lastIndex(of: "\""), start < end {
                                    let desc = String(trimmed[trimmed.index(after: start)..<end])
                                    continuation.resume(returning: desc)
                                    return
                                }
                            }
                        }
                    }
                    continuation.resume(returning: nil)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// Consulta la información técnica detallada usando `-listxml`
    public func querySystemXML(systemName: String, executablePath: String) async -> MAMESystemInfo? {
        guard sanitizeIdentifier(systemName) != nil else { return nil }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = ["-listxml", systemName]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                
                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    
                    let parser = MAMEXMLParser(targetSystemName: systemName)
                    let xmlParser = XMLParser(data: data)
                    xmlParser.delegate = parser
                    if xmlParser.parse(), let info = parser.resultInfo {
                        continuation.resume(returning: info)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - Verificación de ROMs
    
    /// Verifica la integridad del conjunto de ROM mediante `mame -verifyroms`
    public func verifyROM(systemName: String, romPath: String, executablePath: String) async -> (status: GameStatus, details: String) {
        guard sanitizeIdentifier(systemName) != nil else {
            return (.missingFiles, "Identificador de sistema no válido")
        }
        
        let romDir = (romPath as NSString).deletingLastPathComponent
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = ["-rompath", romDir, "-verifyroms", systemName]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                
                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    
                    let output = String(data: data, encoding: .utf8) ?? ""
                    let exitCode = process.terminationStatus
                    
                    if exitCode == 0 && output.contains("romset \"\(systemName)\" is good") {
                        continuation.resume(returning: (.verified, output.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } else if output.contains("not found") {
                        continuation.resume(returning: (.fileNotFound, output.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } else {
                        continuation.resume(returning: (.missingFiles, output.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                } catch {
                    continuation.resume(returning: (.untested, "Error al ejecutar verificación: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    // MARK: - Lanzamiento Seguro de Juegos
    
    /// Comprueba si un juego ya se está ejecutando
    public func isGameRunning(systemName: String) -> Bool {
        processLock.lock()
        defer { processLock.unlock() }
        if let proc = activeProcesses[systemName] {
            return proc.isRunning
        }
        return false
    }
    
    /// Lanza MAME de forma segura y no bloqueante
    public func launchGame(
        game: Game,
        settings: AppSettings,
        onTerminated: (@Sendable (LaunchResult) -> Void)? = nil
    ) -> Result<Void, MAMEError> {
        let systemName = game.systemName
        guard let cleanName = sanitizeIdentifier(systemName) else {
            return .failure(MAMEError("El identificador del juego contiene caracteres no permitidos."))
        }
        
        let validation = validateExecutablePath(settings.mameExecutablePath)
        guard validation.isValid else {
            return .failure(MAMEError(validation.error ?? "Ruta de MAME inválida"))
        }
        
        // Evitar múltiples instancias del mismo juego
        processLock.lock()
        if let currentProc = activeProcesses[cleanName], currentProc.isRunning {
            processLock.unlock()
            return .failure(MAMEError("El juego '\(game.title)' ya está en ejecución."))
        }
        processLock.unlock()
        
        // Verificar que el archivo de ROM exista físicamente en disco
        guard FileManager.default.fileExists(atPath: game.romPath) else {
            return .failure(MAMEError("El archivo ROM no existe en la ruta registrada: \(game.romPath)"))
        }
        
        // Configurar argumentos de forma segura (sin concatenación de shell)
        var args: [String] = [cleanName]
        
        // Configurar rompath: carpeta que contiene este rom + carpetas configuradas
        let romFolder = (game.romPath as NSString).deletingLastPathComponent
        var allRomDirs = [romFolder]
        for dir in settings.romDirectories where !dir.isEmpty && !allRomDirs.contains(dir) {
            allRomDirs.append(dir)
        }
        let joinedRomPath = allRomDirs.joined(separator: ";")
        args.append(contentsOf: ["-rompath", joinedRomPath])
        
        if settings.launchWindowed {
            args.append("-window")
        }
        if settings.skipGameInfo {
            args.append("-skip_gameinfo")
        }
        
        // Argumentos adicionales permitidos y validados explícitamente
        if !settings.additionalArguments.trimmingCharacters(in: .whitespaces).isEmpty {
            let userArgs = settings.additionalArguments
                .components(separatedBy: .whitespaces)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.hasPrefix("-") }
            args.append(contentsOf: userArgs)
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: settings.mameExecutablePath)
        process.arguments = args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let startTime = Date()
        
        process.terminationHandler = { [weak self] proc in
            guard let self = self else { return }
            self.processLock.lock()
            self.activeProcesses.removeValue(forKey: cleanName)
            self.processLock.unlock()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            let exitCode = proc.terminationStatus
            let durationSeconds = Int(Date().timeIntervalSince(startTime))
            
            let success = (exitCode == 0)
            let result = LaunchResult(
                gameId: game.id ?? 0,
                systemName: cleanName,
                timestamp: startTime,
                success: success,
                exitCode: exitCode,
                errorMessage: success ? nil : (output?.trimmingCharacters(in: .whitespacesAndNewlines)),
                commandRun: "\(settings.mameExecutablePath) \(args.joined(separator: " "))"
            )
            
            // Actualizar estadísticas en la base de datos si fue exitoso
            if success {
                DatabaseService.shared.updatePlayStats(systemName: cleanName, durationSeconds: durationSeconds)
            }
            DatabaseService.shared.recordLaunch(result)
            
            onTerminated?(result)
        }
        
        do {
            try process.run()
            processLock.lock()
            activeProcesses[cleanName] = process
            processLock.unlock()
            return .success(())
        } catch {
            return .failure(MAMEError("No se pudo iniciar el proceso de MAME: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Sanitización de Seguridad
    
    /// Asegura que el identificador del sistema MAME sea estrictamente alfanumérico o guión bajo
    public func sanitizeIdentifier(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        if trimmed.rangeOfCharacter(from: allowed.inverted) == nil {
            return trimmed
        }
        return nil
    }
}

// MARK: - Analizador XML SAX de MAME

private final class MAMEXMLParser: NSObject, XMLParserDelegate {
    let targetSystemName: String
    var resultInfo: MAMESystemInfo?
    
    private var insideTargetMachine = false
    private var currentElement = ""
    private var currentText = ""
    
    private var parsedDescription = ""
    private var year: String?
    private var manufacturer: String?
    private var cloneOf: String?
    private var romOf: String?
    private var sampleOf: String?
    private var orientation: String?
    private var players: Int?
    private var hasChd = false
    private var sourceFile: String?
    private var requiredRoms: [String] = []
    
    init(targetSystemName: String) {
        self.targetSystemName = targetSystemName
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""
        
        if elementName == "machine" {
            if let name = attributeDict["name"], name.lowercased() == targetSystemName.lowercased() {
                insideTargetMachine = true
                cloneOf = attributeDict["cloneof"]
                romOf = attributeDict["romof"]
                sampleOf = attributeDict["sampleof"]
                sourceFile = attributeDict["sourcefile"]
            }
        } else if insideTargetMachine {
            if elementName == "display" {
                if let rotate = attributeDict["rotate"] {
                    orientation = "Vertical (\(rotate)°)"
                } else {
                    orientation = "Horizontal"
                }
            } else if elementName == "input" {
                if let pStr = attributeDict["players"], let p = Int(pStr) {
                    players = p
                }
            } else if elementName == "disk" {
                hasChd = true
            } else if elementName == "rom" {
                if let romName = attributeDict["name"] {
                    requiredRoms.append(romName)
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideTargetMachine {
            currentText += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if insideTargetMachine {
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if elementName == "description" {
                parsedDescription = trimmed
            } else if elementName == "year" {
                year = trimmed
            } else if elementName == "manufacturer" {
                manufacturer = trimmed
            } else if elementName == "machine" {
                insideTargetMachine = false
                resultInfo = MAMESystemInfo(
                    systemName: targetSystemName,
                    description: parsedDescription.isEmpty ? targetSystemName : parsedDescription,
                    year: year,
                    manufacturer: manufacturer,
                    cloneOf: cloneOf,
                    romOf: romOf,
                    sampleOf: sampleOf,
                    orientation: orientation ?? "Horizontal",
                    players: players,
                    hasChd: hasChd,
                    sourceFile: sourceFile,
                    requiredRoms: requiredRoms
                )
            }
        }
    }
}

