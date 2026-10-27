import SwiftUI

/// ArcadeTheme define la identidad visual de Arcade Library:
/// Tonos grafito, superficies sobrias con sutiles toques arcade,
/// tipografía moderna y jerarquía visual refinada para macOS.
public enum ArcadeTheme {
    // Fondos principales
    public static let backgroundDark = Color(red: 0.07, green: 0.08, blue: 0.09)
    public static let sidebarBackground = Color(red: 0.10, green: 0.11, blue: 0.13)
    public static let cardBackground = Color(red: 0.12, green: 0.13, blue: 0.16)
    public static let cardHoverBackground = Color(red: 0.16, green: 0.18, blue: 0.22)
    public static let surfaceRaised = Color(red: 0.14, green: 0.15, blue: 0.19)
    public static let borderSubtle = Color.white.opacity(0.08)
    public static let borderFocus = Color(red: 0.35, green: 0.55, blue: 0.95)
    
    // Acentos sobrios (inspiración arcade clásica pero moderna)
    public static let accent = Color(red: 0.25, green: 0.58, blue: 0.95) // Azul cian arcade refinado
    public static let accentGold = Color(red: 0.95, green: 0.72, blue: 0.22) // Oro para favoritos/estrellas
    public static let statusGood = Color(red: 0.22, green: 0.78, blue: 0.46) // Verde verificación correcta
    public static let statusWarning = Color(red: 0.95, green: 0.60, blue: 0.20) // Naranja advertencia/incompleto
    public static let statusBad = Color(red: 0.92, green: 0.30, blue: 0.32) // Rojo error/falta rom
    
    // Texto
    public static let textPrimary = Color.white.opacity(0.95)
    public static let textSecondary = Color.white.opacity(0.65)
    public static let textTertiary = Color.white.opacity(0.40)
    
    // Radios de esquina consistentes
    public static let cornerRadiusSmall: CGFloat = 6
    public static let cornerRadiusMedium: CGFloat = 10
    public static let cornerRadiusLarge: CGFloat = 14
    
    // Animaciones
    public static let quickAnimation = Animation.easeOut(duration: 0.18)
    public static let standardAnimation = Animation.easeInOut(duration: 0.25)
}
