import SwiftUI
import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let iconImg = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = iconImg
        } else if let iconImg = NSImage(contentsOfFile: "Resources/app_icon_1024.jpg") {
            NSApp.applicationIconImage = iconImg
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Mantiene la aplicación viva y permite que los juegos de MAME sigan ejecutándose aunque se cierre la ventana
    }
}
