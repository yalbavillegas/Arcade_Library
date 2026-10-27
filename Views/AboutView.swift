import SwiftUI

/// Vista de créditos y autoría de Arcade Library
public struct AboutView: View {
    public let onClose: () -> Void
    
    @State private var pulseGlow = false
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Cabecera con botón de cierre
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ArcadeTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            
            VStack(spacing: 20) {
                // Emblema visual arcade con el icono oficial
                ZStack {
                    if let iconImg = NSImage(contentsOfFile: "Resources/app_icon_1024.jpg") ?? NSApp.applicationIconImage {
                        Image(nsImage: iconImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 82, height: 82)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(ArcadeTheme.borderSubtle, lineWidth: 1)
                            )
                            .shadow(color: ArcadeTheme.accent.opacity(pulseGlow ? 0.35 : 0.15), radius: 10, x: 0, y: 4)
                    } else {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ArcadeTheme.accent)
                    }
                }
                .onAppear {
                    pulseGlow = true
                }
                
                // Título y Versión
                VStack(spacing: 4) {
                    Text("ARCADE LIBRARY")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundColor(ArcadeTheme.textPrimary)
                    
                    Text("Versión 1.0.0 • Apple Silicon (ARM64)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(ArcadeTheme.textTertiary)
                    
                    Text("Frontend moderno para MAME en macOS")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ArcadeTheme.textSecondary)
                        .padding(.top, 2)
                }
                
                Divider()
                    .background(ArcadeTheme.borderSubtle)
                    .frame(maxWidth: 380)
                
                // Sección de Créditos de Autoría: Yessid Alba
                VStack(spacing: 12) {
                    creditBlock(role: "Ingeniería de software y desarrollo", name: "Yessid Alba")
                    creditBlock(role: "Diseño de interfaz y experiencia de usuario", name: "Yessid Alba")
                    creditBlock(role: "Arquitectura e integración con MAME", name: "Yessid Alba")
                    creditBlock(role: "Dirección técnica del proyecto", name: "Yessid Alba")
                }
                .frame(maxWidth: 380)
                
                Divider()
                    .background(ArcadeTheme.borderSubtle)
                    .frame(maxWidth: 380)
                
                // Tecnologías
                VStack(spacing: 6) {
                    Text("TECNOLOGÍAS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ArcadeTheme.textTertiary)
                    
                    Text("Swift 6 • SwiftUI • macOS AppKit • SQLite3 Nativo • MAME CLI")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ArcadeTheme.textSecondary)
                    
                    Text("Desarrollado de forma nativa para macOS y procesadores Apple Silicon.")
                        .font(.system(size: 11))
                        .foregroundColor(ArcadeTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, 28)
            .padding(.horizontal, 24)
        }
        .frame(width: 460)
        .background(ArcadeTheme.backgroundDark)
        .clipShape(RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: ArcadeTheme.cornerRadiusLarge)
                .stroke(ArcadeTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private func creditBlock(role: String, name: String) -> some View {
        VStack(spacing: 2) {
            Text(role)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ArcadeTheme.textTertiary)
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ArcadeTheme.textPrimary)
        }
    }
}
