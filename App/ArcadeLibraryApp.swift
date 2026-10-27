import SwiftUI

@main
public struct ArcadeLibraryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 920, minHeight: 620)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            SidebarCommands()
        }
    }
}
