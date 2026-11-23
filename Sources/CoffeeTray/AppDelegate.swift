import AppKit
import SwiftUI
import Combine

/// Owns the menu-bar status item, the popover UI, and a single 2-second polling
/// timer. The controller's `isOn` is the source of truth for the icon (kept honest
/// by polling), and the AppDelegate just observes it.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let controller = CaffeinateController()
    private var cancellables = Set<AnyCancellable>()

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        if let button = item.button {
            button.image = StatusIcon.image(active: controller.isOn)
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // SwiftUI form hosted inside an NSPopover. The view sets its own frame.
        let contentView = ContentView(controller: controller)
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        // Restore any in-flight caffeinate from a previous session (recompute-on-relaunch).
        controller.restoreOnLaunch()

        // Single poll: reconcile controller state with reality every 2s. The icon
        // follows `controller.isOn` via Combine below.
        pollTimer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            self?.controller.reconcileProcessState()
        }

        // Icon follows the controller's isOn state.
        controller.$isOn
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] active in
                self?.statusItem.button?.image = StatusIcon.image(active: active)
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Kill all caffeinate processes on quit (user decision: no orphans).
        controller.stop()
        pollTimer?.invalidate()
    }

    // MARK: - Popover

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
