import SwiftUI
import AppKit

/// Vista en lista detallada de la biblioteca de juegos
public struct GameListView: View {
    public let games: [Game]
    @Binding public var selectedGame: Game?
    public let onPlayGame: (Game) -> Void
    public let onToggleFavorite: (Game) -> Void
    public let onRemoveGame: (Game) -> Void
    
    public init(
        games: [Game],
        selectedGame: Binding<Game?>,
        onPlayGame: @escaping (Game) -> Void,
        onToggleFavorite: @escaping (Game) -> Void,
        onRemoveGame: @escaping (Game) -> Void
    ) {
        self.games = games
        self._selectedGame = selectedGame
        self.onPlayGame = onPlayGame
        self.onToggleFavorite = onToggleFavorite
        self.onRemoveGame = onRemoveGame
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Cabecera de columnas
            HStack(spacing: 12) {
                Text("NOMBRE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("FABRICANTE")
                    .frame(width: 150, alignment: .leading)
                Text("AÑO")
                    .frame(width: 60, alignment: .center)
                Text("SISTEMA")
                    .frame(width: 110, alignment: .leading)
                Text("ESTADO")
                    .frame(width: 100, alignment: .leading)
                Text("ÚLTIMO JUEGO")
                    .frame(width: 120, alignment: .trailing)
                Text("PARTIDAS")
                    .frame(width: 70, alignment: .trailing)
                Text("")
                    .frame(width: 40)
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(ArcadeTheme.textTertiary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(ArcadeTheme.surfaceRaised)
            
            Divider()
                .background(ArcadeTheme.borderSubtle)
            
            if games.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundColor(ArcadeTheme.textTertiary)
                    Text("No hay juegos en esta selección")
                        .font(.system(size: 14))
                        .foregroundColor(ArcadeTheme.textSecondary)
                    Spacer()
                }
            } else {
                List(games) { game in
                    gameRow(game)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(
                            selectedGame?.id == game.id ?
                            ArcadeTheme.surfaceRaised :
                            Color.clear
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedGame = game
                        }
                        .contextMenu {
                            Button("Jugar") {
                                onPlayGame(game)
                            }
                            Button(game.isFavorite ? "Quitar de favoritos" : "Añadir a favoritos") {
                                onToggleFavorite(game)
                            }
                            Button("Mostrar archivo en Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: game.romPath)])
                            }
                            Divider()
                            Button("Retirar de la biblioteca", role: .destructive) {
                                onRemoveGame(game)
                            }
                        }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func gameRow(_ game: Game) -> some View {
        HStack(spacing: 12) {
            // Icono / Carátula miniatura + Nombre
            HStack(spacing: 10) {
                // Miniatura o icono
                Group {
                    if let path = game.coverImagePath, let img = NSImage(contentsOfFile: path) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 14))
                            .foregroundColor(ArcadeTheme.accent)
                    }
                }
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ArcadeTheme.textPrimary)
                        .lineLimit(1)
                    Text(game.systemName)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ArcadeTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Fabricante
            Text(game.manufacturer ?? "Desconocido")
                .font(.system(size: 12))
                .foregroundColor(ArcadeTheme.textSecondary)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            // Año
            Text(game.year ?? "—")
                .font(.system(size: 12))
                .foregroundColor(ArcadeTheme.textTertiary)
                .frame(width: 60, alignment: .center)
            
            // Sistema / Orientación
            Text(game.orientation ?? "Arcade")
                .font(.system(size: 12))
                .foregroundColor(ArcadeTheme.textSecondary)
                .lineLimit(1)
                .frame(width: 110, alignment: .leading)
            
            // Estado del ROM
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor(for: game.status))
                    .frame(width: 7, height: 7)
                Text(game.status.localizedDescription)
                    .font(.system(size: 11))
                    .foregroundColor(statusColor(for: game.status))
                    .lineLimit(1)
            }
            .frame(width: 100, alignment: .leading)
            
            // Último juego
            Text(formatDate(game.lastPlayed))
                .font(.system(size: 12))
                .foregroundColor(ArcadeTheme.textTertiary)
                .frame(width: 120, alignment: .trailing)
            
            // Partidas
            Text("\(game.playCount)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(game.playCount > 0 ? ArcadeTheme.accent : ArcadeTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            
            // Favorito
            Button(action: { onToggleFavorite(game) }) {
                Image(systemName: game.isFavorite ? "star.fill" : "star")
                    .foregroundColor(game.isFavorite ? ArcadeTheme.accentGold : Color.white.opacity(0.2))
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .frame(width: 40)
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(for status: GameStatus) -> Color {
        switch status {
        case .verified: return ArcadeTheme.statusGood
        case .missingFiles: return ArcadeTheme.statusWarning
        case .fileNotFound: return ArcadeTheme.statusBad
        case .untested: return Color.gray.opacity(0.7)
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Nunca" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
