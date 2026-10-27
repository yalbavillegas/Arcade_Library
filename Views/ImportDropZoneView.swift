import SwiftUI

/// Vista superpuesta de destino para arrastrar y soltar archivos desde Finder
public struct ImportDropOverlay: View {
    public let isTargeted: Bool
    
    public var body: some View {
        if isTargeted {
            ZStack {
                Color.black.opacity(0.75)
                
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundColor(ArcadeTheme.accent)
                    
                    Text("Suelta los archivos ROM aquí")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Se incorporarán a la biblioteca de MAME sin mover los archivos originales.")
                        .font(.system(size: 13))
                        .foregroundColor(ArcadeTheme.textSecondary)
                }
                .padding(40)
                .background(ArcadeTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusLarge)
                        .stroke(ArcadeTheme.accent, lineWidth: 2)
                )
                .shadow(color: ArcadeTheme.accent.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            .transition(.opacity)
        }
    }
}

/// Modal de progreso durante la importación y análisis de ROMs
public struct ImportProgressModal: View {
    public let progress: Double
    public let statusText: String
    public let onCancel: () -> Void
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.65)
            
            VStack(spacing: 20) {
                HStack {
                    Text("Analizando e importando juegos...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ArcadeTheme.textPrimary)
                    Spacer()
                }
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(ArcadeTheme.accent)
                
                HStack {
                    Text(statusText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(ArcadeTheme.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(ArcadeTheme.accent)
                }
                
                HStack {
                    Spacer()
                    Button("Cancelar", action: onCancel)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding(24)
            .frame(width: 440)
            .background(ArcadeTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusMedium))
            .shadow(radius: 20)
        }
    }
}
