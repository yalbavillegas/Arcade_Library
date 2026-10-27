import Foundation

/// Estructura de resultado de una operación de importación
public struct ImportResult: Sendable {
    public let importedGames: [Game]
    public let duplicateCount: Int
    public let invalidFilesCount: Int
    public let errorMessages: [String]
}

/// Servicio encargado del análisis, validación e importación de archivos ROM a la biblioteca
public final class ImportService: @unchecked Sendable {
    public static let shared = ImportService()
    
    private let validExtensions = ["zip", "7z"]
    
    public init() {}
    
    /// Analiza una lista de URLs (pueden ser archivos individuales o carpetas completas)
    public func collectROMFiles(from urls: [URL]) -> [URL] {
        var romURLsToProcess: [URL] = []
        let fm = FileManager.default
        for url in urls {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                        while let element = enumerator.nextObject() {
                            if let fileURL = element as? URL, validExtensions.contains(fileURL.pathExtension.lowercased()) {
                                romURLsToProcess.append(fileURL)
                            }
                        }
                    }
                } else {
                    if validExtensions.contains(url.pathExtension.lowercased()) {
                        romURLsToProcess.append(url)
                    }
                }
            }
        }
        return romURLsToProcess
    }

    public func importURLs(
        _ urls: [URL],
        settings: AppSettings,
        progressHandler: (@Sendable (Double, String) -> Void)? = nil
    ) async -> ImportResult {
        let romURLsToProcess = collectROMFiles(from: urls)
        
        var imported: [Game] = []
        var duplicates = 0
        var invalid = 0
        var errors: [String] = []
        
        let total = Double(max(romURLsToProcess.count, 1))
        
        for (index, fileURL) in romURLsToProcess.enumerated() {
            let currentProgress = Double(index) / total
            let baseName = fileURL.deletingPathExtension().lastPathComponent.lowercased()
            progressHandler?(currentProgress, "Analizando \(baseName)...")
            
            // Sanitizar nombre de sistema
            guard let systemName = MAMEIntegrationService.shared.sanitizeIdentifier(baseName) else {
                invalid += 1
                errors.append("El archivo '\(fileURL.lastPathComponent)' no tiene un nombre de ROM MAME válido.")
                continue
            }
            
            // Comprobar si ya existe en la base de datos
            if let existing = DatabaseService.shared.getGame(bySystemName: systemName) {
                if settings.preventDuplicates {
                    duplicates += 1
                    continue
                } else {
                    // Si no se previenen duplicados, actualizar la ruta registrada
                    var updated = existing
                    updated.romPath = fileURL.path
                    _ = DatabaseService.shared.saveOrUpdateGame(updated)
                    imported.append(updated)
                    continue
                }
            }
            
            // Consultar metadatos en MAME
            var title = systemName
            var year: String? = nil
            var manufacturer: String? = nil
            var cloneOf: String? = nil
            var romOf: String? = nil
            var sampleOf: String? = nil
            var isParent = true
            var orientation: String? = nil
            var players: Int? = nil
            var hasChd = false
            var sourceFile: String? = nil
            
            // Intento 1: Consultar XML técnico detallado
            if let sysInfo = await MAMEIntegrationService.shared.querySystemXML(systemName: systemName, executablePath: settings.mameExecutablePath) {
                title = sysInfo.description
                year = sysInfo.year
                manufacturer = sysInfo.manufacturer
                cloneOf = sysInfo.cloneOf
                romOf = sysInfo.romOf
                sampleOf = sysInfo.sampleOf
                isParent = (sysInfo.cloneOf == nil || sysInfo.cloneOf!.isEmpty)
                orientation = sysInfo.orientation
                players = sysInfo.players
                hasChd = sysInfo.hasChd
                sourceFile = sysInfo.sourceFile
            } else if let fallbackDesc = await MAMEIntegrationService.shared.queryGameDescription(systemName: systemName, executablePath: settings.mameExecutablePath) {
                // Intento 2: Consulta rápida por listfull
                title = fallbackDesc
            }
            
            // Verificación opcional de integridad
            var initialStatus: GameStatus = .untested
            if settings.autoVerifyOnImport {
                let verification = await MAMEIntegrationService.shared.verifyROM(
                    systemName: systemName,
                    romPath: fileURL.path,
                    executablePath: settings.mameExecutablePath
                )
                initialStatus = verification.status
            }
            
            // Buscar carátula en directorios de imágenes locales
            let dummyGame = Game(
                systemName: systemName,
                title: title,
                cloneOf: cloneOf,
                romPath: fileURL.path
            )
            var foundCover = ArtworkService.shared.resolveArtwork(for: dummyGame, imageDirectories: settings.imageDirectories)
            if foundCover == nil && settings.autoDownloadArtworkOnImport {
                let artworkType = OnlineArtworkType(rawValue: settings.preferredArtworkType) ?? .flyer
                if case .success(let downloadedPath) = await ArtworkService.shared.downloadOnlineArtwork(for: dummyGame, type: artworkType) {
                    foundCover = downloadedPath
                }
            }
            
            let newGame = Game(
                systemName: systemName,
                title: title,
                year: year,
                manufacturer: manufacturer,
                cloneOf: cloneOf,
                romOf: romOf,
                sampleOf: sampleOf,
                isParent: isParent,
                orientation: orientation,
                players: players,
                status: initialStatus,
                romPath: fileURL.path,
                coverImagePath: foundCover,
                addedAt: Date(),
                hasChd: hasChd,
                sourceFile: sourceFile
            )
            
            switch DatabaseService.shared.saveOrUpdateGame(newGame) {
            case .success(let newId):
                var savedGame = newGame
                savedGame.id = newId
                imported.append(savedGame)
            case .failure(let err):
                errors.append("Error guardando '\(title)': \(err.localizedDescription)")
            }
        }
        
        progressHandler?(1.0, "Importación completada")
        return ImportResult(
            importedGames: imported,
            duplicateCount: duplicates,
            invalidFilesCount: invalid,
            errorMessages: errors
        )
    }
}
