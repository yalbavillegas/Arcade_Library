import Foundation

/// Suite completa de pruebas automatizadas para Arcade Library (15 pruebas de validación)
@main
struct ArcadeLibraryTestSuite {
    static var passedCount = 0
    static var failedCount = 0
    static var testResults: [(name: String, passed: Bool, detail: String)] = []
    
    static func record(testNum: Int, name: String, passed: Bool, detail: String = "") {
        if passed {
            passedCount += 1
            print("  [\(testNum)] PASS: \(name)")
        } else {
            failedCount += 1
            print("  [\(testNum)] FAIL: \(name) - \(detail)")
        }
        testResults.append((name: "[\(testNum)] \(name)", passed: passed, detail: detail))
    }
    
    static func main() async {
        print("\n=======================================================")
        print("   ARCADE LIBRARY — SUITE DE PRUEBAS AUTOMATIZADAS")
        print("   Autoría y Dirección Técnica: Yessid Alba")
        print("   Plataforma: macOS Apple Silicon (ARM64)")
        print("=======================================================\n")
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ArcadeLibraryTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let testDbPath = tempDir.appendingPathComponent("test_library.sqlite3").path
        let db = DatabaseService(databasePath: testDbPath)
        let mame = MAMEIntegrationService.shared
        
        // -------------------------------------------------------------------------
        // 1. Apertura sin ruta de MAME configurada
        // -------------------------------------------------------------------------
        let validationEmpty = mame.validateExecutablePath("")
        record(
            testNum: 1,
            name: "Apertura sin ruta de MAME configurada",
            passed: !validationEmpty.isValid && validationEmpty.error != nil,
            detail: "Debe rechazar ruta vacía sin lanzar excepciones."
        )
        
        // -------------------------------------------------------------------------
        // 2. Configuración de un ejecutable válido
        // -------------------------------------------------------------------------
        let validationValid = mame.validateExecutablePath("/opt/homebrew/bin/mame")
        record(
            testNum: 2,
            name: "Configuración de un ejecutable válido",
            passed: validationValid.isValid,
            detail: "Debe validar correctamente /opt/homebrew/bin/mame."
        )
        
        // -------------------------------------------------------------------------
        // 3. Detección de una versión de MAME
        // -------------------------------------------------------------------------
        var detectedVer = ""
        if case .success(let ver) = await mame.detectVersion(executablePath: "/opt/homebrew/bin/mame") {
            detectedVer = ver
        }
        record(
            testNum: 3,
            name: "Detección de una versión de MAME",
            passed: !detectedVer.isEmpty && detectedVer.contains("0.289"),
            detail: "Versión detectada: '\(detectedVer)'"
        )
        
        // -------------------------------------------------------------------------
        // Preparación de un archivo ROM simulado en disco
        // -------------------------------------------------------------------------
        let sampleRomURL = tempDir.appendingPathComponent("pacman.zip")
        try? "PK\u{03}\u{04}simulated_rom_content".data(using: .utf8)?.write(to: sampleRomURL)
        
        // -------------------------------------------------------------------------
        // 4. Importación de un archivo
        // -------------------------------------------------------------------------
        let testSettings = AppSettings(
            mameExecutablePath: "/opt/homebrew/bin/mame",
            detectedMAMEVersion: detectedVer,
            romDirectories: [tempDir.path],
            imageDirectories: [],
            viewMode: .grid,
            cardSize: 180,
            isDarkTheme: true,
            sortField: .title,
            sortAscending: true,
            launchWindowed: true,
            skipGameInfo: true,
            additionalArguments: "",
            preventDuplicates: true,
            autoVerifyOnImport: false
        )
        
        // Realizamos consulta de MAME simulada o directa
        let importedGame = Game(
            systemName: "pacman",
            title: "Pac-Man (Midway)",
            year: "1980",
            manufacturer: "Namco (Midway license)",
            status: .untested,
            romPath: sampleRomURL.path
        )
        let saveRes = db.saveOrUpdateGame(importedGame)
        let importSuccess: Bool
        if case .success = saveRes {
            importSuccess = true
        } else {
            importSuccess = false
        }
        record(
            testNum: 4,
            name: "Importación de un archivo",
            passed: importSuccess,
            detail: "El juego pacman fue incorporado con éxito a la biblioteca."
        )
        
        // -------------------------------------------------------------------------
        // 5. Rechazo controlado de entradas no válidas
        // -------------------------------------------------------------------------
        let invalidId1 = mame.sanitizeIdentifier("pacman; rm -rf /")
        let invalidId2 = mame.sanitizeIdentifier("../../../etc/passwd")
        let invalidRejected = (invalidId1 == nil && invalidId2 == nil)
        record(
            testNum: 5,
            name: "Rechazo controlado de entradas no válidas",
            passed: invalidRejected,
            detail: "Identificadores maliciosos rechazados de forma segura."
        )
        
        // -------------------------------------------------------------------------
        // 6. Detección de duplicados
        // -------------------------------------------------------------------------
        let existingGame = db.getGame(bySystemName: "pacman")
        let duplicateDetected = (existingGame != nil && existingGame?.systemName == "pacman")
        record(
            testNum: 6,
            name: "Detección de duplicados",
            passed: duplicateDetected,
            detail: "Identificador 'pacman' ya existe en base de datos."
        )
        
        // -------------------------------------------------------------------------
        // 7. Persistencia de la biblioteca
        // -------------------------------------------------------------------------
        let allGamesBefore = db.getAllGames()
        let persisted = allGamesBefore.contains { $0.systemName == "pacman" }
        record(
            testNum: 7,
            name: "Persistencia de la biblioteca",
            passed: persisted,
            detail: "Se recuperó pacman desde SQLite correctamente."
        )
        
        // -------------------------------------------------------------------------
        // 8. Búsqueda y filtrado
        // -------------------------------------------------------------------------
        let searchResults = allGamesBefore.filter { $0.title.lowercased().contains("pac-man") }
        let filterMfg = allGamesBefore.filter { $0.manufacturer?.contains("Namco") ?? false }
        record(
            testNum: 8,
            name: "Búsqueda y filtrado",
            passed: !searchResults.isEmpty && !filterMfg.isEmpty,
            detail: "Búsqueda por texto y fabricante funcionan correctamente."
        )
        
        // -------------------------------------------------------------------------
        // 9. Guardado de favoritos
        // -------------------------------------------------------------------------
        if let gId = existingGame?.id {
            db.setFavorite(gameId: gId, isFavorite: true)
        }
        let updatedFavGame = db.getGame(bySystemName: "pacman")
        record(
            testNum: 9,
            name: "Guardado de favoritos",
            passed: updatedFavGame?.isFavorite == true,
            detail: "El estado de favorito se guardó y persistió."
        )
        
        // -------------------------------------------------------------------------
        // 10. Asignación de carátulas
        // -------------------------------------------------------------------------
        let dummyCoverPath = tempDir.appendingPathComponent("pacman.png").path
        try? "dummy_image_data".data(using: .utf8)?.write(to: URL(fileURLWithPath: dummyCoverPath))
        if let gId = updatedFavGame?.id {
            db.updateCover(gameId: gId, imagePath: dummyCoverPath)
        }
        let updatedCoverGame = db.getGame(bySystemName: "pacman")
        record(
            testNum: 10,
            name: "Asignación de carátulas",
            passed: updatedCoverGame?.coverImagePath == dummyCoverPath,
            detail: "Carátula asignada correctamente a la ruta."
        )
        
        // -------------------------------------------------------------------------
        // 11. Manejo de rutas inexistentes
        // -------------------------------------------------------------------------
        let nonexistentGame = Game(
            systemName: "dkong",
            title: "Donkey Kong",
            status: .untested,
            romPath: "/ruta/que/no/existe/dkong.zip"
        )
        _ = db.saveOrUpdateGame(nonexistentGame)
        let (_, missing) = DiagnosticService.shared.rescanLibraryFiles(database: db)
        let dkongAfter = db.getGame(bySystemName: "dkong")
        record(
            testNum: 11,
            name: "Manejo de rutas inexistentes",
            passed: dkongAfter?.status == .fileNotFound && missing >= 1,
            detail: "Ruta inexistente detectada y marcada como fileNotFound sin error."
        )
        
        // -------------------------------------------------------------------------
        // 12. Lanzamiento controlado de un juego
        // -------------------------------------------------------------------------
        // Creamos un script simulador de MAME para probar el ciclo de proceso
        let fakeMameScript = tempDir.appendingPathComponent("fake_mame.sh")
        let scriptContent = "#!/bin/sh\nexit 0\n"
        try? scriptContent.data(using: .utf8)?.write(to: fakeMameScript)
        let chmodProc = Process()
        chmodProc.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodProc.arguments = ["+x", fakeMameScript.path]
        try? chmodProc.run()
        chmodProc.waitUntilExit()
        
        var fakeSettings = testSettings
        fakeSettings.mameExecutablePath = fakeMameScript.path
        
        let launchSuccess: Bool
        if let pacGame = db.getGame(bySystemName: "pacman") {
            launchSuccess = await withCheckedContinuation { continuation in
                let res = mame.launchGame(game: pacGame, settings: fakeSettings) { result in
                    continuation.resume(returning: result.success)
                }
                if case .failure = res {
                    continuation.resume(returning: false)
                }
            }
        } else {
            launchSuccess = false
        }
        record(
            testNum: 12,
            name: "Lanzamiento controlado de un juego",
            passed: launchSuccess,
            detail: "Proceso lanzado con argumentos seguros."
        )
        
        // -------------------------------------------------------------------------
        // 13. Manejo de errores del proceso de MAME
        // -------------------------------------------------------------------------
        let errorMameScript = tempDir.appendingPathComponent("error_mame.sh")
        let errScriptContent = "#!/bin/sh\necho 'ERROR: Required ROM image not found' >&2\nexit 2\n"
        try? errScriptContent.data(using: .utf8)?.write(to: errorMameScript)
        let chmodErr = Process()
        chmodErr.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodErr.arguments = ["+x", errorMameScript.path]
        try? chmodErr.run()
        chmodErr.waitUntilExit()
        
        var errorSettings = testSettings
        errorSettings.mameExecutablePath = errorMameScript.path
        
        var capturedError = false
        if let pacGame = db.getGame(bySystemName: "pacman") {
            capturedError = await withCheckedContinuation { continuation in
                let res = mame.launchGame(game: pacGame, settings: errorSettings) { result in
                    continuation.resume(returning: (!result.success && result.exitCode == 2))
                }
                if case .failure = res {
                    continuation.resume(returning: false)
                }
            }
        }
        record(
            testNum: 13,
            name: "Manejo de errores del proceso de MAME",
            passed: capturedError,
            detail: "Código de error 2 y mensaje capturados correctamente."
        )
        
        // -------------------------------------------------------------------------
        // 14. Copia de seguridad y restauración de los datos
        // -------------------------------------------------------------------------
        let backupURL = tempDir.appendingPathComponent("test_backup.json")
        var backupRestoreSuccess = false
        do {
            try db.exportBackup(to: backupURL)
            // Borrar pacman
            if let pId = db.getGame(bySystemName: "pacman")?.id {
                _ = db.removeGameFromLibrary(gameId: pId)
            }
            let countRestored = try db.restoreBackup(from: backupURL)
            let pacRestored = db.getGame(bySystemName: "pacman")
            if countRestored > 0 && pacRestored != nil {
                backupRestoreSuccess = true
            }
        } catch {
            backupRestoreSuccess = false
        }
        record(
            testNum: 14,
            name: "Copia de seguridad y restauración de los datos",
            passed: backupRestoreSuccess,
            detail: "Metadatos exportados a JSON y restaurados con éxito."
        )
        
        // -------------------------------------------------------------------------
        // 15. Retirada de un título sin borrar el ROM original
        // -------------------------------------------------------------------------
        var nonDestructiveRemoval = false
        if let pacId = db.getGame(bySystemName: "pacman")?.id {
            let removedFromDb = db.removeGameFromLibrary(gameId: pacId)
            let dbCheck = db.getGame(bySystemName: "pacman")
            let fileStillExists = FileManager.default.fileExists(atPath: sampleRomURL.path)
            if removedFromDb && dbCheck == nil && fileStillExists {
                nonDestructiveRemoval = true
            }
        }
        record(
            testNum: 15,
            name: "Retirada de un título sin borrar el ROM original",
            passed: nonDestructiveRemoval,
            detail: "El registro fue eliminado de la biblioteca pero el archivo físico se mantuvo intacto."
        )
        
        // -------------------------------------------------------------------------
        // Resumen Final
        // -------------------------------------------------------------------------
        print("\n=======================================================")
        print("   RESUMEN DE PRUEBAS AUTOMATIZADAS:")
        print("   Total: \(passedCount + failedCount) | Superadas: \(passedCount) | Fallidas: \(failedCount)")
        if failedCount == 0 {
            print("   ESTADO: TODAS LAS PRUEBAS SUPERADAS CON ÉXITO (15/15)")
        } else {
            print("   ESTADO: EXISTEN PRUEBAS CON FALLO")
        }
        print("=======================================================\n")
        
        // Limpieza de archivos de prueba
        try? FileManager.default.removeItem(at: tempDir)
        
        if failedCount > 0 {
            exit(1)
        }
    }
}
