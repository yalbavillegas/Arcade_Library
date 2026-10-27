import Foundation

/// Representa un juego arcade registrado en la biblioteca.
public struct Game: Identifiable, Codable, Hashable, Sendable {
    public var id: Int64?
    public var systemName: String           // Identificador MAME (ej: "pacman")
    public var title: String                // Nombre completo/comercial (ej: "Pac-Man (Midway)")
    public var year: String?                // Año de lanzamiento (ej: "1980")
    public var manufacturer: String?        // Fabricante/desarrollador (ej: "Namco")
    public var cloneOf: String?             // Identificador del padre si es clon
    public var romOf: String?               // Conjunto de ROM padre
    public var sampleOf: String?            // Samples requeridos
    public var isParent: Bool               // Es el juego original/padre
    public var orientation: String?         // Orientación de pantalla (ej: "Vertical 90°", "Horizontal")
    public var players: Int?                // Número de jugadores soportados
    public var status: GameStatus           // Estado de verificación del ROM
    public var romPath: String              // Ruta al archivo ROM original (.zip, .7z, carpeta)
    public var coverImagePath: String?      // Ruta local a la carátula/captura asignada
    public var playCount: Int               // Veces jugado
    public var lastPlayed: Date?            // Fecha de última partida
    public var totalPlayTimeSeconds: Int    // Tiempo acumulado en segundos
    public var isFavorite: Bool             // Marcado como favorito
    public var addedAt: Date                // Fecha de incorporación a la biblioteca
    public var notes: String?               // Notas o dependencias adicionales
    public var hasChd: Bool                 // Requiere imagen de disco duro CHD
    public var sourceFile: String?          // Archivo fuente del controlador en MAME (ej: "pacman.cpp")
    
    public init(
        id: Int64? = nil,
        systemName: String,
        title: String,
        year: String? = nil,
        manufacturer: String? = nil,
        cloneOf: String? = nil,
        romOf: String? = nil,
        sampleOf: String? = nil,
        isParent: Bool = true,
        orientation: String? = nil,
        players: Int? = nil,
        status: GameStatus = .untested,
        romPath: String,
        coverImagePath: String? = nil,
        playCount: Int = 0,
        lastPlayed: Date? = nil,
        totalPlayTimeSeconds: Int = 0,
        isFavorite: Bool = false,
        addedAt: Date = Date(),
        notes: String? = nil,
        hasChd: Bool = false,
        sourceFile: String? = nil
    ) {
        self.id = id
        self.systemName = systemName
        self.title = title
        self.year = year
        self.manufacturer = manufacturer
        self.cloneOf = cloneOf
        self.romOf = romOf
        self.sampleOf = sampleOf
        self.isParent = isParent
        self.orientation = orientation
        self.players = players
        self.status = status
        self.romPath = romPath
        self.coverImagePath = coverImagePath
        self.playCount = playCount
        self.lastPlayed = lastPlayed
        self.totalPlayTimeSeconds = totalPlayTimeSeconds
        self.isFavorite = isFavorite
        self.addedAt = addedAt
        self.notes = notes
        self.hasChd = hasChd
        self.sourceFile = sourceFile
    }
}

/// Estado de verificación del ROM
public enum GameStatus: String, Codable, CaseIterable, Sendable {
    case verified = "verified"         // ROM verificado y completo
    case missingFiles = "missing"     // Faltan archivos o dependencias
    case fileNotFound = "not_found"   // El archivo en la ruta registrada no existe
    case untested = "untested"         // Sin verificar aún
    
    public var localizedDescription: String {
        switch self {
        case .verified: return "Verificado"
        case .missingFiles: return "Incompleto o con problemas"
        case .fileNotFound: return "Archivo no encontrado"
        case .untested: return "Sin verificar"
        }
    }
    
    public var badgeColorName: String {
        switch self {
        case .verified: return "green"
        case .missingFiles: return "orange"
        case .fileNotFound: return "red"
        case .untested: return "gray"
        }
    }
}
