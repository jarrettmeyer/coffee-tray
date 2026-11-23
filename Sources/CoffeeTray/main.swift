import AppKit

// CoffeeTray is a menu-bar-only app (LSUIElement). We boot a manual NSApplication
// instead of using @main/SwiftUI App so we control the status item, popover, and
// the polling timer that drives the icon state.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // belt-and-suspenders with LSUIElement: no Dock icon
app.run()
