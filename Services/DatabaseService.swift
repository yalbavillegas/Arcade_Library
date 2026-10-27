import Foundation
import SQLite3

/// Servicio de persistencia basado en SQLite para Arcade Library
public final class DatabaseService: @unchecked Sendable {
    public static let shared = DatabaseService()
    
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.arcadelibrary.database", qos: .userInitiated)
    public let databasePath: String
    
    public init(databasePath: String? = nil) {
        if let customPath = databasePath {
            self.databasePath = customPath
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let arcadeDir = appSupport.appendingPathComponent("ArcadeLibrary", isDirectory: true)
            if (try? FileManager.default.createDirectory(at: arcadeDir, withIntermediateDirectories: true)) != nil {
                self.databasePath = arcadeDir.appendingPathComponent("library.sqlite3").path
            } else {
                let localDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".arcade_data", isDirectory: true)
                try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)
                self.databasePath = localDir.appendingPathComponent("library.sqlite3").path
            }
        }
        openDatabase()
        createTables()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    // MARK: - Inicialización de Base de Datos
    
    private func openDatabase() {
        if sqlite3_open(databasePath, &db) != SQLITE_OK {
            print("Error al abrir base de datos SQLite en: \(databasePath)")
        }
    }
    
    private func createTables() {
        let createGamesTable = """
        CREATE TABLE IF NOT EXISTS games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            system_name TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            year TEXT,
            manufacturer TEXT,
            clone_of TEXT,
            rom_of TEXT,
            sample_of TEXT,
            is_parent INTEGER NOT NULL DEFAULT 1,
            orientation TEXT,
            players INTEGER,
            status TEXT NOT NULL DEFAULT 'untested',
            rom_path TEXT NOT NULL,
            cover_image_path TEXT,
            play_count INTEGER NOT NULL DEFAULT 0,
            last_played REAL,
            total_play_time_seconds INTEGER NOT NULL DEFAULT 0,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            added_at REAL NOT NULL,
            notes TEXT,
            has_chd INTEGER NOT NULL DEFAULT 0,
            source_file TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_games_system_name ON games(system_name);
        CREATE INDEX IF NOT EXISTS idx_games_is_favorite ON games(is_favorite);
        CREATE INDEX IF NOT EXISTS idx_games_year ON games(year);
        CREATE INDEX IF NOT EXISTS idx_games_manufacturer ON games(manufacturer);
        
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        
        CREATE TABLE IF NOT EXISTS launch_history (
            id TEXT PRIMARY KEY,
            game_id INTEGER,
            system_name TEXT NOT NULL,
            timestamp REAL NOT NULL,
            success INTEGER NOT NULL,
            exit_code INTEGER NOT NULL,
            error_message TEXT,
            command_run TEXT NOT NULL
        );
        """
        
        dbQueue.sync {
            var errorMsg: UnsafeMutablePointer<CChar>?
            if sqlite3_exec(db, createGamesTable, nil, nil, &errorMsg) != SQLITE_OK {
                if let errorMsg = errorMsg {
                    print("Error creando tablas: \(String(cString: errorMsg))")
                    sqlite3_free(errorMsg)
                }
            }
        }
    }
    
    // MARK: - Operaciones CRUD de Juegos
    
    public func saveOrUpdateGame(_ game: Game) -> Result<Int64, Error> {
        return dbQueue.sync {
            let sql = """
            INSERT INTO games (
                system_name, title, year, manufacturer, clone_of, rom_of, sample_of,
                is_parent, orientation, players, status, rom_path, cover_image_path,
                play_count, last_played, total_play_time_seconds, is_favorite,
                added_at, notes, has_chd, source_file
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(system_name) DO UPDATE SET
                title = excluded.title,
                year = excluded.year,
                manufacturer = excluded.manufacturer,
                clone_of = excluded.clone_of,
                rom_of = excluded.rom_of,
                sample_of = excluded.sample_of,
                is_parent = excluded.is_parent,
                orientation = excluded.orientation,
                players = excluded.players,
                status = excluded.status,
                rom_path = excluded.rom_path,
                cover_image_path = COALESCE(excluded.cover_image_path, games.cover_image_path),
                notes = excluded.notes,
                has_chd = excluded.has_chd,
                source_file = excluded.source_file;
            """
            
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                let err = String(cString: sqlite3_errmsg(db))
                return .failure(NSError(domain: "DatabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: err]))
            }
            defer { sqlite3_finalize(statement) }
            
            sqlite3_bind_text(statement, 1, (game.systemName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (game.title as NSString).utf8String, -1, nil)
            bindOptionalText(statement, index: 3, value: game.year)
            bindOptionalText(statement, index: 4, value: game.manufacturer)
            bindOptionalText(statement, index: 5, value: game.cloneOf)
            bindOptionalText(statement, index: 6, value: game.romOf)
            bindOptionalText(statement, index: 7, value: game.sampleOf)
            sqlite3_bind_int(statement, 8, game.isParent ? 1 : 0)
            bindOptionalText(statement, index: 9, value: game.orientation)
            if let players = game.players {
                sqlite3_bind_int(statement, 10, Int32(players))
            } else {
                sqlite3_bind_null(statement, 10)
            }
            sqlite3_bind_text(statement, 11, (game.status.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 12, (game.romPath as NSString).utf8String, -1, nil)
            bindOptionalText(statement, index: 13, value: game.coverImagePath)
            sqlite3_bind_int(statement, 14, Int32(game.playCount))
            if let lp = game.lastPlayed {
                sqlite3_bind_double(statement, 15, lp.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 15)
            }
            sqlite3_bind_int(statement, 16, Int32(game.totalPlayTimeSeconds))
            sqlite3_bind_int(statement, 17, game.isFavorite ? 1 : 0)
            sqlite3_bind_double(statement, 18, game.addedAt.timeIntervalSince1970)
            bindOptionalText(statement, index: 19, value: game.notes)
            sqlite3_bind_int(statement, 20, game.hasChd ? 1 : 0)
            bindOptionalText(statement, index: 21, value: game.sourceFile)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                let lastId = sqlite3_last_insert_rowid(db)
                return .success(lastId)
            } else {
                let err = String(cString: sqlite3_errmsg(db))
                return .failure(NSError(domain: "DatabaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: err]))
            }
        }
    }
    
    public func getAllGames() -> [Game] {
        return dbQueue.sync {
            let sql = "SELECT * FROM games ORDER BY title COLLATE NOCASE ASC;"
            var statement: OpaquePointer?
            var results: [Game] = []
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return []
            }
            defer { sqlite3_finalize(statement) }
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let game = parseGame(from: statement) {
                    results.append(game)
                }
            }
            return results
        }
    }
    
    public func getGame(bySystemName name: String) -> Game? {
        return dbQueue.sync {
            let sql = "SELECT * FROM games WHERE system_name = ? LIMIT 1;"
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
            defer { sqlite3_finalize(statement) }
            
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                return parseGame(from: statement)
            }
            return nil
        }
    }
    
    public func setFavorite(gameId: Int64, isFavorite: Bool) {
        dbQueue.sync {
            let sql = "UPDATE games SET is_favorite = ? WHERE id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, isFavorite ? 1 : 0)
                sqlite3_bind_int64(statement, 2, gameId)
                _ = sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }
    
    public func updateCover(gameId: Int64, imagePath: String?) {
        dbQueue.sync {
            let sql = "UPDATE games SET cover_image_path = ? WHERE id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                bindOptionalText(statement, index: 1, value: imagePath)
                sqlite3_bind_int64(statement, 2, gameId)
                _ = sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }
    
    public func updatePlayStats(systemName: String, durationSeconds: Int = 0) {
        dbQueue.sync {
            let now = Date().timeIntervalSince1970
            let sql = """
            UPDATE games SET
                play_count = play_count + 1,
                last_played = ?,
                total_play_time_seconds = total_play_time_seconds + ?
            WHERE system_name = ?;
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, now)
                sqlite3_bind_int(statement, 2, Int32(durationSeconds))
                sqlite3_bind_text(statement, 3, (systemName as NSString).utf8String, -1, nil)
                _ = sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }
    
    public func updateStatus(gameId: Int64, status: GameStatus) {
        dbQueue.sync {
            let sql = "UPDATE games SET status = ? WHERE id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (status.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_int64(statement, 2, gameId)
                _ = sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }
    
    /// Retira el juego de la biblioteca. NUNCA borra el archivo físico original.
    public func removeGameFromLibrary(gameId: Int64) -> Bool {
        return dbQueue.sync {
            let sql = "DELETE FROM games WHERE id = ?;"
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
            defer { sqlite3_finalize(statement) }
            
            sqlite3_bind_int64(statement, 1, gameId)
            return sqlite3_step(statement) == SQLITE_DONE
        }
    }
    
    // MARK: - Historial de Lanzamiento
    
    public func recordLaunch(_ result: LaunchResult) {
        dbQueue.sync {
            let sql = """
            INSERT INTO launch_history (id, game_id, system_name, timestamp, success, exit_code, error_message, command_run)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (result.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_bind_int64(statement, 2, result.gameId)
                sqlite3_bind_text(statement, 3, (result.systemName as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 4, result.timestamp.timeIntervalSince1970)
                sqlite3_bind_int(statement, 5, result.success ? 1 : 0)
                sqlite3_bind_int(statement, 6, result.exitCode)
                bindOptionalText(statement, index: 7, value: result.errorMessage)
                sqlite3_bind_text(statement, 8, (result.commandRun as NSString).utf8String, -1, nil)
                _ = sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }
    
    public func getRecentLaunches(limit: Int = 50) -> [LaunchResult] {
        return dbQueue.sync {
            let sql = "SELECT * FROM launch_history ORDER BY timestamp DESC LIMIT ?;"
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
            defer { sqlite3_finalize(statement) }
            
            sqlite3_bind_int(statement, 1, Int32(limit))
            var results: [LaunchResult] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                let idStr = String(cString: sqlite3_column_text(statement, 0))
                let gameId = sqlite3_column_int64(statement, 1)
                let sysName = String(cString: sqlite3_column_text(statement, 2))
                let ts = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
                let success = sqlite3_column_int(statement, 4) == 1
                let exitCode = sqlite3_column_int(statement, 5)
                var errMsg: String? = nil
                if let errText = sqlite3_column_text(statement, 6) {
                    errMsg = String(cString: errText)
                }
                let cmd = String(cString: sqlite3_column_text(statement, 7))
                
                results.append(LaunchResult(
                    id: UUID(uuidString: idStr) ?? UUID(),
                    gameId: gameId,
                    systemName: sysName,
                    timestamp: ts,
                    success: success,
                    exitCode: exitCode,
                    errorMessage: errMsg,
                    commandRun: cmd
                ))
            }
            return results
        }
    }
    
    // MARK: - Configuración Persistente
    
    public func saveSettings(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings),
           let json = String(data: data, encoding: .utf8) {
            dbQueue.sync {
                let sql = "INSERT INTO settings (key, value) VALUES ('app_settings', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value;"
                var statement: OpaquePointer?
                if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_text(statement, 1, (json as NSString).utf8String, -1, nil)
                    _ = sqlite3_step(statement)
                    sqlite3_finalize(statement)
                }
            }
        }
    }
    
    public func loadSettings() -> AppSettings {
        return dbQueue.sync {
            let sql = "SELECT value FROM settings WHERE key = 'app_settings' LIMIT 1;"
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return AppSettings.default
            }
            defer { sqlite3_finalize(statement) }
            
            if sqlite3_step(statement) == SQLITE_ROW {
                if let text = sqlite3_column_text(statement, 0),
                   let data = String(cString: text).data(using: .utf8),
                   let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
                    return settings
                }
            }
            return AppSettings.default
        }
    }
    
    // MARK: - Copia de Seguridad y Restauración
    
    public struct BackupData: Codable {
        public let version: String
        public let exportedAt: Date
        public let games: [Game]
        public let settings: AppSettings
    }
    
    public func exportBackup(to destinationURL: URL) throws {
        let games = getAllGames()
        let settings = loadSettings()
        let backup = BackupData(
            version: "1.0",
            exportedAt: Date(),
            games: games,
            settings: settings
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)
        try data.write(to: destinationURL)
    }
    
    public func restoreBackup(from sourceURL: URL) throws -> Int {
        let data = try Data(contentsOf: sourceURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)
        
        saveSettings(backup.settings)
        var restoredCount = 0
        for game in backup.games {
            if case .success = saveOrUpdateGame(game) {
                restoredCount += 1
            }
        }
        return restoredCount
    }
    
    // MARK: - Ayudantes Privados
    
    private func parseGame(from statement: OpaquePointer?) -> Game? {
        guard let statement = statement else { return nil }
        
        let id = sqlite3_column_int64(statement, 0)
        let systemName = String(cString: sqlite3_column_text(statement, 1))
        let title = String(cString: sqlite3_column_text(statement, 2))
        let year = columnOptionalText(statement, index: 3)
        let manufacturer = columnOptionalText(statement, index: 4)
        let cloneOf = columnOptionalText(statement, index: 5)
        let romOf = columnOptionalText(statement, index: 6)
        let sampleOf = columnOptionalText(statement, index: 7)
        let isParent = sqlite3_column_int(statement, 8) == 1
        let orientation = columnOptionalText(statement, index: 9)
        let players = sqlite3_column_type(statement, 10) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 10)) : nil
        let statusRaw = String(cString: sqlite3_column_text(statement, 11))
        let status = GameStatus(rawValue: statusRaw) ?? .untested
        let romPath = String(cString: sqlite3_column_text(statement, 12))
        let coverImagePath = columnOptionalText(statement, index: 13)
        let playCount = Int(sqlite3_column_int(statement, 14))
        let lastPlayedDouble = sqlite3_column_double(statement, 15)
        let lastPlayed = lastPlayedDouble > 0 ? Date(timeIntervalSince1970: lastPlayedDouble) : nil
        let totalPlayTime = Int(sqlite3_column_int(statement, 16))
        let isFavorite = sqlite3_column_int(statement, 17) == 1
        let addedAtDouble = sqlite3_column_double(statement, 18)
        let addedAt = Date(timeIntervalSince1970: addedAtDouble)
        let notes = columnOptionalText(statement, index: 19)
        let hasChd = sqlite3_column_int(statement, 20) == 1
        let sourceFile = columnOptionalText(statement, index: 21)
        
        return Game(
            id: id,
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
            status: status,
            romPath: romPath,
            coverImagePath: coverImagePath,
            playCount: playCount,
            lastPlayed: lastPlayed,
            totalPlayTimeSeconds: totalPlayTime,
            isFavorite: isFavorite,
            addedAt: addedAt,
            notes: notes,
            hasChd: hasChd,
            sourceFile: sourceFile
        )
    }
    
    private func bindOptionalText(_ statement: OpaquePointer?, index: Int32, value: String?) {
        if let value = value {
            sqlite3_bind_text(statement, index, (value as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, index)
        }
    }
    
    private func columnOptionalText(_ statement: OpaquePointer?, index: Int32) -> String? {
        if sqlite3_column_type(statement, index) == SQLITE_NULL {
            return nil
        }
        guard let text = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: text)
    }
}
