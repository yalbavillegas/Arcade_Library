import SwiftUI
import AppKit

/// Ficha detallada con toda la información técnica, estadísticas y acciones de un juego
public struct GameDetailSheet: View {
    public let game: Game
    public let settings: AppSettings
    public let onClose: () -> Void
    public let onPlayGame: (Game) -> Void
    public let onToggleFavorite: (Game) -> Void
    public let onCoverUpdated: (Game, String?) -> Void
    public let onStatusUpdated: (Game, GameStatus) -> Void
    public let onRemoveGame: (Game) -> Void
    
    @State private var isVerifying = false
    @State private var verificationMessage: String? = nil
    @State private var showRemoveConfirmation = false
    @State private var isDownloadingCover = false
    @State private var coverDownloadMessage: String? = nil
    
    public init(
        game: Game,
        settings: AppSettings,
        onClose: @escaping () -> Void,
        onPlayGame: @escaping (Game) -> Void,
        onToggleFavorite: @escaping (Game) -> Void,
        onCoverUpdated: @escaping (Game, String?) -> Void,
        onStatusUpdated: @escaping (Game, GameStatus) -> Void,
        onRemoveGame: @escaping (Game) -> Void
    ) {
        self.game = game
        self.settings = settings
        self.onClose = onClose
        self.onPlayGame = onPlayGame
        self.onToggleFavorite = onToggleFavorite
        self.onCoverUpdated = onCoverUpdated
        self.onStatusUpdated = onStatusUpdated
        self.onRemoveGame = onRemoveGame
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Cabecera de la ficha
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ArcadeTheme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(game.systemName)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(ArcadeTheme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ArcadeTheme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        if let year = game.year {
                            Text(year)
                                .font(.system(size: 13))
                                .foregroundColor(ArcadeTheme.textSecondary)
                        }
                        if let mfg = game.manufacturer {
                            Text("•")
                                .foregroundColor(ArcadeTheme.textTertiary)
                            Text(mfg)
                                .font(.system(size: 13))
                                .foregroundColor(ArcadeTheme.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Favorito y cerrar
                HStack(spacing: 12) {
                    Button(action: { onToggleFavorite(game) }) {
                        Image(systemName: game.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 18))
                            .foregroundColor(game.isFavorite ? ArcadeTheme.accentGold : ArcadeTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help(game.isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ArcadeTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(ArcadeTheme.surfaceRaised)
            
            Divider()
                .background(ArcadeTheme.borderSubtle)
            
            // Contenido con scroll
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Sección superior: Carátula y Botón Principal de Lanzamiento
                    HStack(alignment: .top, spacing: 24) {
                        // Carátula con opción de cambio
                        VStack(spacing: 8) {
                            coverImageView
                                .frame(width: 170, height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusMedium)
                                        .stroke(ArcadeTheme.borderSubtle, lineWidth: 1)
                                )
                            
                            HStack(spacing: 10) {
                                Button("Examinar...") {
                                    selectCustomCover()
                                }
                                .font(.system(size: 11))
                                .buttonStyle(.link)
                                
                                if isDownloadingCover {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                } else {
                                    Menu {
                                        Button("Descargar Flyer / Carátula") {
                                            downloadCoverOnline(type: .flyer)
                                        }
                                        Button("Descargar Captura de juego") {
                                            downloadCoverOnline(type: .snap)
                                        }
                                        Button("Descargar Pantalla de título") {
                                            downloadCoverOnline(type: .title)
                                        }
                                    } label: {
                                        HStack(spacing: 3) {
                                            Image(systemName: "arrow.down.circle")
                                            Text("En línea...")
                                        }
                                        .font(.system(size: 11))
                                        .foregroundColor(ArcadeTheme.accent)
                                    }
                                    .menuStyle(.borderlessButton)
                                }
                            }
                            
                            if let msg = coverDownloadMessage {
                                Text(msg)
                                    .font(.system(size: 10))
                                    .foregroundColor(msg.contains("correctamente") ? ArcadeTheme.statusGood : ArcadeTheme.statusWarning)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 170)
                            }
                        }
                        
                        // Panel de lanzamiento y estado principal
                        VStack(alignment: .leading, spacing: 16) {
                            Button(action: { onPlayGame(game) }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("JUGAR AHORA")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [ArcadeTheme.accent, Color(red: 0.15, green: 0.45, blue: 0.85)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusSmall))
                                .shadow(color: ArcadeTheme.accent.opacity(0.35), radius: 6, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
                            
                            // Estado de verificación
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(statusColor)
                                        .frame(width: 10, height: 10)
                                    Text("Estado: \(game.status.localizedDescription)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(statusColor)
                                    
                                    Spacer()
                                    
                                    if isVerifying {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    } else {
                                        Button("Verificar ROM") {
                                            runVerification()
                                        }
                                        .font(.system(size: 12))
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                                
                                if let msg = verificationMessage {
                                    Text(msg)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(ArcadeTheme.textSecondary)
                                        .padding(8)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(12)
                            .background(ArcadeTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusSmall))
                            
                            // Estadísticas de uso
                            HStack(spacing: 20) {
                                statItem(title: "Partidas", value: "\(game.playCount)")
                                statItem(title: "Última vez", value: formatDate(game.lastPlayed))
                                statItem(title: "Tiempo total", value: formatPlayTime(game.totalPlayTimeSeconds))
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    Divider()
                        .background(ArcadeTheme.borderSubtle)
                    
                    // Metadatos Técnicos
                    VStack(alignment: .leading, spacing: 14) {
                        Text("INFORMACIÓN TÉCNICA Y SISTEMA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(ArcadeTheme.textTertiary)
                        
                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                            GridRow {
                                metaLabel("Fabricante")
                                metaValue(game.manufacturer ?? "No disponible")
                                metaLabel("Año")
                                metaValue(game.year ?? "Desconocido")
                            }
                            GridRow {
                                metaLabel("Orientación")
                                metaValue(game.orientation ?? "Horizontal estándar")
                                metaLabel("Jugadores")
                                metaValue(game.players != nil ? "\(game.players!) jugador(es)" : "Desconocido")
                            }
                            GridRow {
                                metaLabel("Tipo de ROM")
                                metaValue(game.isParent ? "Original / Principal (Parent)" : "Clon de \(game.cloneOf ?? "otro sistema")")
                                metaLabel("Requiere CHD")
                                metaValue(game.hasChd ? "Sí (Disco duro virtual)" : "No")
                            }
                            if let romOf = game.romOf {
                                GridRow {
                                    metaLabel("ROM Padre")
                                    metaValue(romOf)
                                    metaLabel("Samples")
                                    metaValue(game.sampleOf ?? "Ninguno")
                                }
                            }
                            if let src = game.sourceFile {
                                GridRow {
                                    metaLabel("Controlador MAME")
                                    metaValue(src)
                                    metaLabel("MAME Detectado")
                                    metaValue(settings.detectedMAMEVersion ?? "Instalación local")
                                }
                            }
                        }
                        .font(.system(size: 13))
                    }
                    
                    Divider()
                        .background(ArcadeTheme.borderSubtle)
                    
                    // Ubicación del archivo y Acciones
                    VStack(alignment: .leading, spacing: 12) {
                        Text("UBICACIÓN DEL ARCHIVO")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(ArcadeTheme.textTertiary)
                        
                        HStack {
                            Text(game.romPath)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(ArcadeTheme.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            Button("Mostrar en Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: game.romPath)])
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(10)
                        .background(ArcadeTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    // Zona de peligro: Retirar de la biblioteca
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Retirar juego de la biblioteca")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(ArcadeTheme.textPrimary)
                            Text("Se eliminará de la base de datos de Arcade Library. El archivo ROM original NO será borrado del disco.")
                                .font(.system(size: 11))
                                .foregroundColor(ArcadeTheme.textTertiary)
                        }
                        Spacer()
                        Button("Retirar", role: .destructive) {
                            showRemoveConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(24)
            }
        }
        .frame(minWidth: 620, minHeight: 520)
        .background(ArcadeTheme.backgroundDark)
        .confirmationDialog(
            "¿Retirar '\(game.title)' de la biblioteca?",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Retirar de la biblioteca", role: .destructive) {
                onRemoveGame(game)
                onClose()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción eliminará el registro de la biblioteca pero mantendrá intacto el archivo ROM en su ubicación actual.")
        }
    }
    
    // MARK: - Subcomponentes
    
    @ViewBuilder
    private var coverImageView: some View {
        if let path = game.coverImagePath, let img = NSImage(contentsOfFile: path) {
            Image(nsImage: img)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                ArcadeTheme.cardBackground
                VStack(spacing: 8) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 36))
                        .foregroundColor(ArcadeTheme.accent.opacity(0.6))
                    Text(game.systemName)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(ArcadeTheme.textTertiary)
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch game.status {
        case .verified: return ArcadeTheme.statusGood
        case .missingFiles: return ArcadeTheme.statusWarning
        case .fileNotFound: return ArcadeTheme.statusBad
        case .untested: return Color.gray.opacity(0.8)
        }
    }
    
    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(ArcadeTheme.textPrimary)
        }
    }
    
    private func metaLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(ArcadeTheme.textTertiary)
    }
    
    private func metaValue(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(ArcadeTheme.textPrimary)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Nunca" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatPlayTime(_ seconds: Int) -> String {
        if seconds <= 0 { return "0 min" }
        let mins = seconds / 60
        let hours = mins / 60
        if hours > 0 {
            return "\(hours)h \(mins % 60)m"
        }
        return "\(mins) min"
    }
    
    private func runVerification() {
        isVerifying = true
        verificationMessage = nil
        Task {
            let res = await MAMEIntegrationService.shared.verifyROM(
                systemName: game.systemName,
                romPath: game.romPath,
                executablePath: settings.mameExecutablePath
            )
            await MainActor.run {
                self.isVerifying = false
                self.verificationMessage = res.details
                self.onStatusUpdated(game, res.status)
            }
        }
    }
    
    private func selectCustomCover() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .webP]
        panel.title = "Seleccionar carátula para \(game.title)"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let newPath = try? ArtworkService.shared.assignCustomArtwork(sourceURL: url, forSystemName: game.systemName) {
                onCoverUpdated(game, newPath)
            }
        }
    }
    
    private func downloadCoverOnline(type: OnlineArtworkType) {
        isDownloadingCover = true
        coverDownloadMessage = nil
        Task {
            let res = await ArtworkService.shared.downloadOnlineArtwork(for: game, type: type)
            await MainActor.run {
                self.isDownloadingCover = false
                switch res {
                case .success(let path):
                    self.onCoverUpdated(game, path)
                    self.coverDownloadMessage = "Carátula descargada correctamente."
                case .failure(let err):
                    self.coverDownloadMessage = err.localizedDescription
                }
            }
        }
    }
}
