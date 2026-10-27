import Foundation
import AppKit

/// Tipos de carátulas o ilustraciones disponibles en repositorios públicos en línea
public enum OnlineArtworkType: String, CaseIterable, Sendable {
    case flyer = "flyer"   // Flyer o carátula publicitaria arcade del mueble
    case snap = "snap"     // Captura de pantalla de la partida (Gameplay)
    case title = "title"   // Pantalla de título o marquesina
    
    public var localizedName: String {
        switch self {
        case .flyer: return "Carátula / Flyer publicitario"
        case .snap: return "Captura de pantalla (Snap)"
        case .title: return "Pantalla de título (Title)"
        }
    }
    
    public var adbPathSegment: String {
        switch self {
        case .flyer: return "flyers"
        case .snap: return "snaps"
        case .title: return "titles"
        }
    }
}

/// Gestiona la detección, asignación, descarga en línea y resolución de carátulas e ilustraciones de juegos
public final class ArtworkService: @unchecked Sendable {
    public static let shared = ArtworkService()
    
    private let supportedExtensions = ["png", "jpg", "jpeg", "webp"]
    
    public init() {}
    
    // MARK: - Directorio Local de Carátulas
    
    public func getCoversDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("ArcadeLibrary/Covers", isDirectory: true)
        if (try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)) != nil {
            return appDir
        } else {
            let localDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".arcade_data/Covers", isDirectory: true)
            try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)
            return localDir
        }
    }
    
    // MARK: - Resolución Local
    
    /// Busca una imagen representativa para el juego según las prioridades locales:
    /// 1. Carátula personalizada previamente asignada
    /// 2. Directorios de imágenes configurados por el usuario (<systemName>.png, etc.)
    /// 3. Directorio de capturas/artwork de MAME si existe
    public func resolveArtwork(for game: Game, imageDirectories: [String]) -> String? {
        let fm = FileManager.default
        
        // 1. Carátula personalizada o previamente descargada
        if let customPath = game.coverImagePath, fm.fileExists(atPath: customPath) {
            return customPath
        }
        
        // 2. Comprobar en la misma carpeta del ROM si hay una imagen con el mismo nombre
        let romFolder = (game.romPath as NSString).deletingLastPathComponent
        if let localMatch = findImage(named: game.systemName, inDirectory: romFolder) {
            return localMatch
        }
        
        // 3. Directorios de imágenes configurados por el usuario
        for dir in imageDirectories {
            if let match = findImage(named: game.systemName, inDirectory: dir) {
                return match
            }
            // También comprobar por nombre del padre si es un clon
            if let parent = game.cloneOf, let parentMatch = findImage(named: parent, inDirectory: dir) {
                return parentMatch
            }
        }
        
        return nil
    }
    
    /// Busca un archivo de imagen en un directorio con extensiones compatibles
    public func findImage(named baseName: String, inDirectory dirPath: String) -> String? {
        let fm = FileManager.default
        for ext in supportedExtensions {
            let candidate = (dirPath as NSString).appendingPathComponent("\(baseName).\(ext)")
            if fm.fileExists(atPath: candidate) {
                return candidate
            }
            // Probar en mayúsculas también
            let candidateUpper = (dirPath as NSString).appendingPathComponent("\(baseName).\(ext.uppercased())")
            if fm.fileExists(atPath: candidateUpper) {
                return candidateUpper
            }
        }
        return nil
    }
    
    /// Copia una imagen seleccionada por el usuario a la carpeta de datos de la aplicación y devuelve la ruta permanente
    public func assignCustomArtwork(sourceURL: URL, forSystemName systemName: String) throws -> String {
        let coversDir = getCoversDirectory()
        let ext = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension
        let destURL = coversDir.appendingPathComponent("\(systemName)_\(UUID().uuidString.prefix(8)).\(ext)")
        
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
        return destURL.path
    }
    
    // MARK: - Descarga en Línea (Arcade Database & Libretro Thumbnails)
    
    /// Descarga la carátula o captura desde fuentes públicas y legales (Arcade Database / Libretro)
    public func downloadOnlineArtwork(
        for game: Game,
        type: OnlineArtworkType = .flyer
    ) async -> Result<String, Error> {
        let systemName = game.systemName.lowercased()
        
        // Construir candidatos de URLs públicas y abiertas
        var candidateURLs: [URL] = []
        
        // 1. Arcade Database (ArcadeItalia ADB) - Repositorio directo por sistema MAME
        if let url1 = URL(string: "https://adb.arcadeitalia.net/media/mame.current/\(type.adbPathSegment)/\(systemName).png") {
            candidateURLs.append(url1)
        }
        // 2. Si es un clon, intentar con el juego original/padre
        if let parent = game.cloneOf, !parent.isEmpty,
           let parentUrl = URL(string: "https://adb.arcadeitalia.net/media/mame.current/\(type.adbPathSegment)/\(parent.lowercased()).png") {
            candidateURLs.append(parentUrl)
        }
        // 3. Arcade Database servicio dinámico
        if let urlService = URL(string: "https://adb.arcadeitalia.net/service_show.php?q=\(type.rawValue)&game_name=\(systemName)") {
            candidateURLs.append(urlService)
        }
        // 4. Libretro Thumbnails MAME (GitHub raw)
        let cleanedTitle = cleanTitleForLibretro(game.title)
        let libretroFolder = type == .title ? "Named_Titles" : (type == .snap ? "Named_Snaps" : "Named_Boxarts")
        if let encoded = cleanedTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
           let urlLibretro = URL(string: "https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/\(libretroFolder)/\(encoded).png") {
            candidateURLs.append(urlLibretro)
        }
        
        let session = URLSession(configuration: .default)
        
        for candidateURL in candidateURLs {
            do {
                var request = URLRequest(url: candidateURL)
                request.timeoutInterval = 12
                request.setValue("ArcadeLibrary/1.0.0 (Macintosh; Apple Silicon)", forHTTPHeaderField: "User-Agent")
                
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continue
                }
                
                // Validar que la respuesta sea realmente una imagen decodificable y no un error HTML
                guard let _ = NSImage(data: data), data.count > 1024 else {
                    continue
                }
                
                // Guardar la imagen en el directorio de carátulas
                let coversDir = getCoversDirectory()
                let destinationURL = coversDir.appendingPathComponent("\(systemName)_\(type.rawValue).png")
                
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try? FileManager.default.removeItem(at: destinationURL)
                }
                try data.write(to: destinationURL)
                
                return .success(destinationURL.path)
            } catch {
                continue
            }
        }
        
        return .failure(NSError(domain: "ArtworkService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No se encontró carátula en línea para '\(game.title)' (\(systemName))"]))
    }
    
    /// Descarga en lote carátulas para todos los juegos que carezcan de imagen
    public func downloadBatchMissingArtwork(
        games: [Game],
        type: OnlineArtworkType = .flyer,
        progressHandler: (@Sendable (Double, String) -> Void)? = nil
    ) async -> (downloaded: Int, failed: Int) {
        let missing = games.filter { $0.coverImagePath == nil || !FileManager.default.fileExists(atPath: $0.coverImagePath!) }
        guard !missing.isEmpty else {
            progressHandler?(1.0, "Todos los juegos ya tienen carátula")
            return (0, 0)
        }
        
        var downloaded = 0
        var failed = 0
        let total = Double(missing.count)
        
        for (index, game) in missing.enumerated() {
            let progress = Double(index) / total
            progressHandler?(progress, "Descargando (\(index + 1)/\(missing.count)): \(game.title)...")
            
            let res = await downloadOnlineArtwork(for: game, type: type)
            switch res {
            case .success(let imagePath):
                if let gameId = game.id {
                    DatabaseService.shared.updateCover(gameId: gameId, imagePath: imagePath)
                }
                downloaded += 1
            case .failure:
                failed += 1
            }
        }
        
        progressHandler?(1.0, "Descarga completada: \(downloaded) obtenidas.")
        return (downloaded, failed)
    }
    
    // MARK: - Formateo de Título para Libretro
    
    private func cleanTitleForLibretro(_ title: String) -> String {
        // Libretro reemplaza caracteres inválidos en nombres de archivo
        var cleaned = title
        let forbidden = ["&", "*", "/", ":", "`", "<", ">", "?", "\\", "|"]
        for char in forbidden {
            cleaned = cleaned.replacingOccurrences(of: char, with: "_")
        }
        return cleaned
    }
}
