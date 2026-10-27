import Foundation

/// Opciones de ordenación de la biblioteca
public enum SortField: String, Codable, CaseIterable, Sendable {
    case title = "title"
    case year = "year"
    case manufacturer = "manufacturer"
    case addedAt = "addedAt"
    case lastPlayed = "lastPlayed"
    case playCount = "playCount"
    
    public var localizedName: String {
        switch self {
        case .title: return "Nombre"
        case .year: return "Año"
        case .manufacturer: return "Fabricante"
        case .addedAt: return "Fecha de incorporación"
        case .lastPlayed: return "Último juego"
        case .playCount: return "Más jugados"
        }
    }
}

/// Modo de visualización de la biblioteca
public enum LibraryViewMode: String, Codable, CaseIterable, Sendable {
    case grid = "grid"
    case list = "list"
    
    public var localizedName: String {
        switch self {
        case .grid: return "Cuadrícula"
        case .list: return "Lista"
        }
    }
}

/// Configuración global persistente de Arcade Library
public struct AppSettings: Codable, Sendable {
    public var mameExecutablePath: String
    public var detectedMAMEVersion: String?
    public var romDirectories: [String]
    public var imageDirectories: [String]
    public var viewMode: LibraryViewMode
    public var cardSize: Double
    public var isDarkTheme: Bool
    public var sortField: SortField
    public var sortAscending: Bool
    public var launchWindowed: Bool
    public var skipGameInfo: Bool
    public var additionalArguments: String
    public var preventDuplicates: Bool
    public var autoVerifyOnImport: Bool
    public var autoDownloadArtworkOnImport: Bool
    public var preferredArtworkType: String
    
    public init(
        mameExecutablePath: String = "/opt/homebrew/bin/mame",
        detectedMAMEVersion: String? = "0.289",
        romDirectories: [String] = [],
        imageDirectories: [String] = [],
        viewMode: LibraryViewMode = .grid,
        cardSize: Double = 180.0,
        isDarkTheme: Bool = true,
        sortField: SortField = .title,
        sortAscending: Bool = true,
        launchWindowed: Bool = false,
        skipGameInfo: Bool = true,
        additionalArguments: String = "",
        preventDuplicates: Bool = true,
        autoVerifyOnImport: Bool = true,
        autoDownloadArtworkOnImport: Bool = false,
        preferredArtworkType: String = "flyer"
    ) {
        self.mameExecutablePath = mameExecutablePath
        self.detectedMAMEVersion = detectedMAMEVersion
        self.romDirectories = romDirectories
        self.imageDirectories = imageDirectories
        self.viewMode = viewMode
        self.cardSize = cardSize
        self.isDarkTheme = isDarkTheme
        self.sortField = sortField
        self.sortAscending = sortAscending
        self.launchWindowed = launchWindowed
        self.skipGameInfo = skipGameInfo
        self.additionalArguments = additionalArguments
        self.preventDuplicates = preventDuplicates
        self.autoVerifyOnImport = autoVerifyOnImport
        self.autoDownloadArtworkOnImport = autoDownloadArtworkOnImport
        self.preferredArtworkType = preferredArtworkType
    }
    
    public static let `default` = AppSettings()
}
