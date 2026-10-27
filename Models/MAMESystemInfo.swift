import Foundation

/// Información técnica extraída de MAME para un sistema o máquina específica
public struct MAMESystemInfo: Sendable {
    public let systemName: String
    public let description: String
    public let year: String?
    public let manufacturer: String?
    public let cloneOf: String?
    public let romOf: String?
    public let sampleOf: String?
    public let orientation: String?
    public let players: Int?
    public let hasChd: Bool
    public let sourceFile: String?
    public let requiredRoms: [String]
    
    public init(
        systemName: String,
        description: String,
        year: String? = nil,
        manufacturer: String? = nil,
        cloneOf: String? = nil,
        romOf: String? = nil,
        sampleOf: String? = nil,
        orientation: String? = nil,
        players: Int? = nil,
        hasChd: Bool = false,
        sourceFile: String? = nil,
        requiredRoms: [String] = []
    ) {
        self.systemName = systemName
        self.description = description
        self.year = year
        self.manufacturer = manufacturer
        self.cloneOf = cloneOf
        self.romOf = romOf
        self.sampleOf = sampleOf
        self.orientation = orientation
        self.players = players
        self.hasChd = hasChd
        self.sourceFile = sourceFile
        self.requiredRoms = requiredRoms
    }
}

/// Resultado de un intento de lanzamiento de un juego
public struct LaunchResult: Identifiable, Sendable {
    public let id: UUID
    public let gameId: Int64
    public let systemName: String
    public let timestamp: Date
    public let success: Bool
    public let exitCode: Int32
    public let errorMessage: String?
    public let commandRun: String
    
    public init(
        id: UUID = UUID(),
        gameId: Int64,
        systemName: String,
        timestamp: Date = Date(),
        success: Bool,
        exitCode: Int32,
        errorMessage: String? = nil,
        commandRun: String
    ) {
        self.id = id
        self.gameId = gameId
        self.systemName = systemName
        self.timestamp = timestamp
        self.success = success
        self.exitCode = exitCode
        self.errorMessage = errorMessage
        self.commandRun = commandRun
    }
}
