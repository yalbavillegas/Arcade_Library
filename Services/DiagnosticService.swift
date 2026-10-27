import Foundation

/// Información del diagnóstico del entorno y rutas
public struct DiagnosticReport: Sendable {
    public let appVersion: String
    public let osVersion: String
    public let architecture: String
    public let mamePath: String
    public let isMameValid: Bool
    public let mameVersion: String?
    public let mamePathError: String?
    public let totalGamesInLibrary: Int
    public let verifiedGamesCount: Int
    public let problematicGamesCount: Int
    public let missingFilesGamesCount: Int
    public let configuredRomDirsStatus: [(path: String, exists: Bool)]
    public let configuredImageDirsStatus: [(path: String, exists: Bool)]
}

/// Servicio de diagnóstico y validación de Arcade Library
public final class DiagnosticService: @unchecked Sendable {
    public static let shared = DiagnosticService()
    
    public init() {}
    
    public func generateReport(settings: AppSettings, database: DatabaseService = .shared) async -> DiagnosticReport {
        let appVersion = "1.0.0 (Apple Silicon)"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #if arch(arm64)
        let arch = "Apple Silicon (ARM64)"
        #else
        let arch = "x86_64"
        #endif
        
        let mameValidation = MAMEIntegrationService.shared.validateExecutablePath(settings.mameExecutablePath)
        var detectedVer: String? = nil
        if mameValidation.isValid {
            if case .success(let ver) = await MAMEIntegrationService.shared.detectVersion(executablePath: settings.mameExecutablePath) {
                detectedVer = ver
            }
        }
        
        let allGames = database.getAllGames()
        let verifiedCount = allGames.filter { $0.status == .verified }.count
        let probCount = allGames.filter { $0.status == .missingFiles }.count
        let missingFilesCount = allGames.filter { $0.status == .fileNotFound }.count
        
        let fm = FileManager.default
        let romDirsStatus = settings.romDirectories.map { (path: $0, exists: fm.fileExists(atPath: $0)) }
        let imgDirsStatus = settings.imageDirectories.map { (path: $0, exists: fm.fileExists(atPath: $0)) }
        
        return DiagnosticReport(
            appVersion: appVersion,
            osVersion: osVersion,
            architecture: arch,
            mamePath: settings.mameExecutablePath,
            isMameValid: mameValidation.isValid,
            mameVersion: detectedVer,
            mamePathError: mameValidation.error,
            totalGamesInLibrary: allGames.count,
            verifiedGamesCount: verifiedCount,
            problematicGamesCount: probCount,
            missingFilesGamesCount: missingFilesCount,
            configuredRomDirsStatus: romDirsStatus,
            configuredImageDirsStatus: imgDirsStatus
        )
    }
    
    /// Vuelve a analizar la biblioteca para detectar archivos que hayan dejado de existir o discos desconectados
    public func rescanLibraryFiles(database: DatabaseService = .shared) -> (scanned: Int, missingFound: Int) {
        let games = database.getAllGames()
        let fm = FileManager.default
        var missing = 0
        
        for game in games {
            guard let gameId = game.id else { continue }
            if !fm.fileExists(atPath: game.romPath) {
                database.updateStatus(gameId: gameId, status: .fileNotFound)
                missing += 1
            } else if game.status == .fileNotFound {
                // El archivo volvió a estar disponible (por ej. disco externo reconectado)
                database.updateStatus(gameId: gameId, status: .untested)
            }
        }
        return (games.count, missing)
    }
}
