import SwiftUI
import AppKit

/// Tarjeta visual de un juego en la vista de cuadrícula
public struct GameCardView: View {
    public let game: Game
    public let cardSize: CGFloat
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onPlay: () -> Void
    public let onToggleFavorite: () -> Void
    
    @State private var isHovered = false
    
    public init(
        game: Game,
        cardSize: CGFloat,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onPlay: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void
    ) {
        self.game = game
        self.cardSize = cardSize
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onPlay = onPlay
        self.onToggleFavorite = onToggleFavorite
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Contenedor de la carátula
            ZStack(alignment: .topTrailing) {
                artworkView
                    .frame(width: cardSize, height: cardSize * 1.32)
                    .clipShape(RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusMedium, style: .continuous))
                
                // Botón de favorito superior derecho
                Button(action: onToggleFavorite) {
                    Image(systemName: game.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(game.isFavorite ? ArcadeTheme.accentGold : Color.white.opacity(0.6))
                        .padding(6)
                        .background(Color.black.opacity(0.65))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
                .opacity(game.isFavorite || isHovered ? 1.0 : 0.0)
                .animation(ArcadeTheme.quickAnimation, value: isHovered)
                
                // Indicador de estado del ROM en la esquina inferior izquierda
                VStack {
                    Spacer()
                    HStack {
                        statusBadge
                        Spacer()
                        // Botón de reproducción rápida al hacer hover
                        if isHovered {
                            Button(action: onPlay) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(ArcadeTheme.accent)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(isSelected ? ArcadeTheme.borderFocus : (isHovered ? Color.white.opacity(0.2) : ArcadeTheme.borderSubtle), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.35 : 0.15), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
            
            // Textos descriptivos del juego
            VStack(alignment: .leading, spacing: 3) {
                Text(game.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ArcadeTheme.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                HStack(spacing: 6) {
                    if let year = game.year, !year.isEmpty {
                        Text(year)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(ArcadeTheme.textTertiary)
                    }
                    if let manufacturer = game.manufacturer, !manufacturer.isEmpty {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(ArcadeTheme.textTertiary)
                        Text(manufacturer)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(ArcadeTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: cardSize, alignment: .leading)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusLarge, style: .continuous)
                .fill(isSelected ? ArcadeTheme.surfaceRaised : (isHovered ? ArcadeTheme.cardHoverBackground : Color.clear))
        )
        .onHover { hovering in
            withAnimation(ArcadeTheme.quickAnimation) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
    
    // MARK: - Vista de Imagen o Reserva Elegante
    
    @ViewBuilder
    private var artworkView: some View {
        if let coverPath = game.coverImagePath, let nsImage = NSImage(contentsOfFile: coverPath) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            // Tarjeta de reserva elegante cuando no hay imagen disponible
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        ArcadeTheme.cardBackground,
                        Color(red: 0.08, green: 0.09, blue: 0.11)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: cardSize * 0.22, weight: .light))
                        .foregroundColor(ArcadeTheme.accent.opacity(0.8))
                    
                    VStack(spacing: 4) {
                        Text(game.systemName.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(ArcadeTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                        
                        Text(game.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ArcadeTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                            .lineLimit(3)
                    }
                }
                .padding(8)
            }
        }
    }
    
    // MARK: - Badge de Estado
    
    private var statusBadge: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .shadow(color: statusColor.opacity(0.6), radius: 3, x: 0, y: 0)
    }
    
    private var statusColor: Color {
        switch game.status {
        case .verified: return ArcadeTheme.statusGood
        case .missingFiles: return ArcadeTheme.statusWarning
        case .fileNotFound: return ArcadeTheme.statusBad
        case .untested: return Color.gray.opacity(0.7)
        }
    }
}
