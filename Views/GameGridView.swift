import SwiftUI

/// Vista en cuadrícula de la biblioteca de juegos
public struct GameGridView: View {
    public let games: [Game]
    public let cardSize: CGFloat
    @Binding public var selectedGame: Game?
    public let onPlayGame: (Game) -> Void
    public let onToggleFavorite: (Game) -> Void
    
    public init(
        games: [Game],
        cardSize: CGFloat,
        selectedGame: Binding<Game?>,
        onPlayGame: @escaping (Game) -> Void,
        onToggleFavorite: @escaping (Game) -> Void
    ) {
        self.games = games
        self.cardSize = cardSize
        self._selectedGame = selectedGame
        self.onPlayGame = onPlayGame
        self.onToggleFavorite = onToggleFavorite
    }
    
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: cardSize, maximum: cardSize * 1.3), spacing: 20)]
    }
    
    public var body: some View {
        ScrollView {
            if games.isEmpty {
                emptyLibraryView
            } else {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(games) { game in
                        GameCardView(
                            game: game,
                            cardSize: cardSize,
                            isSelected: selectedGame?.id == game.id,
                            onSelect: {
                                selectedGame = game
                            },
                            onPlay: {
                                onPlayGame(game)
                            },
                            onToggleFavorite: {
                                onToggleFavorite(game)
                            }
                        )
                    }
                }
                .padding(24)
            }
        }
    }
    
    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.3x3.topleft.filled")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            Text("No se encontraron juegos")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ArcadeTheme.textSecondary)
            
            Text("Arrastra archivos ROM (.zip o .7z) a esta ventana o utiliza el botón '+' para agregarlos a tu biblioteca.")
                .font(.system(size: 13))
                .foregroundColor(ArcadeTheme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, 60)
    }
}
