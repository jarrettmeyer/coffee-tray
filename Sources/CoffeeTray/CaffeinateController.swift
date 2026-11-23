import Foundation
import ServiceManagement

/// Drives the `caffeinate` process and holds all user-facing state.
///
/// Caffeinate is treated as a global singleton: the app reflects whether ANY
/// caffeinate process is running (ours or one started from the command line before
/// launch), and turning it off kills ALL caffeinate processes. This avoids the
/// problems of multiple concurrent sleep assertions.
///
/// Responsibilities:
/// - Mirror the "is caffeinate running" state (via ProcessDetector polling).
/// - Spawn a process with the chosen flags if none is running.
/// - Kill ALL caffeinate processes when turned off.
/// - Persist the target stop time so a relaunch can recompute remaining seconds.
/// - Register/unregister the app as a login item via SMAppService.
final class CaffeinateController: ObservableObject {

    // MARK: - Constants

    private static let caffeinatePath = "/usr/bin/caffeinate"
    private static let targetDateKey = "com.jarrettmeyer.coffeetray.targetDate"

    // MARK: - Published UI state

    /// Mirrors whether any caffeinate process is running (ours or external).
    /// The poll timer keeps this in sync with reality.
    @Published var isOn = false
    @Published var flagD = false
    @Published var flagI = true   // matches default `caffeinate` (idle sleep prevention)
    @Published var flagS = false
    @Published var flagU = false
    @Published var timeoutMode: TimeoutMode = .off
    @Published var targetDate: Date = Date(timeIntervalSinceNow: 3600)
    @Published var launchAtLogin = false

    enum TimeoutMode: String, CaseIterable, Identifiable {
        case off, until
        var id: String { rawValue }
        var label: String {
            switch self {
            case .off: return "Off"
            case .until: return "Until"
            }
        }
    }

    // MARK: - Private process state

    /// The process we spawned, if any. May be nil if caffeinate is running but we
    /// didn't start it (e.g. started from the CLI).
    private var process: Process?

    // MARK: - Init

    init() {
        refreshLaunchAtLoginStatus()
    }

    // MARK: - Start / Stop

    /// Turn caffeinate on. If a caffeinate process is already running (ours or
    /// external), this just reflects that state — it does NOT spawn a second one.
    func start() {
        if ProcessDetector.isCaffeinateRunning() {
            isOn = true
            return
        }
        do {
            try spawn()
            isOn = true
        } catch {
            isOn = false
            print("Failed to start caffeinate: \(error)")
        }
    }

    /// Turn caffeinate off. Kills ALL running caffeinate processes (ours and any
    /// started from the command line) to avoid orphaned assertions.
    func stop() {
        ProcessDetector.killAllCaffeinate()
        process = nil
        isOn = false
        clearStoredTarget()
    }

    /// Restart caffeinate with current settings if it's currently running, so flag/timeout
    /// edits take effect immediately. Kills any existing process first.
    func restartIfRunning() {
        guard isOn else { return }
        ProcessDetector.killAllCaffeinate()
        process = nil
        do {
            try spawn()
        } catch {
            isOn = false
            print("Failed to restart caffeinate: \(error)")
        }
    }

    // MARK: - Poll reconciliation

    /// Called by the poll timer. Syncs `isOn` with reality: if any caffeinate is
    /// running we're on; if none is running we're off. This is what keeps the toggle
    /// honest when a process started from the CLI, or when our own process exits
    /// on its own (e.g. its -t timeout elapsed).
    func reconcileProcessState() {
        let running = ProcessDetector.isCaffeinateRunning()
        if running != isOn {
            isOn = running
            if !running {
                process = nil
                clearStoredTarget()
            }
        }
    }

    // MARK: - Process spawn

    private func spawn() throws {
        var args: [String] = []

        if flagD { args.append("-d") }
        if flagI { args.append("-i") }
        if flagS { args.append("-s") }
        if flagU { args.append("-u") }

        // Compute target Date + seconds, persist for recompute-on-relaunch.
        let target = computedTargetDate()
        if let target {
            let seconds = max(1, Int(target.timeIntervalSinceNow.rounded()))
            args.append("-t")
            args.append(String(seconds))
            storeTargetDate(target)
        } else {
            clearStoredTarget()
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: Self.caffeinatePath)
        proc.arguments = args
        try proc.run()
        process = proc
    }

    // MARK: - Restore on relaunch (recompute-on-relaunch)

    /// On app launch, if a target stop time was persisted from a prior session and is still
    /// in the future, recompute the remaining seconds and respawn caffeinate with `-t`.
    /// If the target is in the past or absent, sync to current reality.
    func restoreOnLaunch() {
        // If caffeinate is already running (e.g. started from CLI), just reflect it.
        if ProcessDetector.isCaffeinateRunning() {
            isOn = true
            return
        }

        guard let stored = storedTargetDate() else {
            isOn = false
            return
        }
        if stored > Date() {
            // Recompute remaining time and respawn with a fresh -t.
            targetDate = stored
            timeoutMode = .until
            do {
                try spawn()
                isOn = true
            } catch {
                isOn = false
                clearStoredTarget()
                print("Failed to restore caffeinate: \(error)")
            }
        } else {
            // Deadline already passed while we were closed.
            clearStoredTarget()
            isOn = false
        }
    }

    // MARK: - Target date computation + persistence

    private func computedTargetDate() -> Date? {
        switch timeoutMode {
        case .off:
            return nil
        case .until:
            return targetDate
        }
    }

    private func storeTargetDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: Self.targetDateKey)
    }

    private func storedTargetDate() -> Date? {
        UserDefaults.standard.object(forKey: Self.targetDateKey) as? Date
    }

    private func clearStoredTarget() {
        UserDefaults.standard.removeObject(forKey: Self.targetDateKey)
    }

    // MARK: - Launch at login (SMAppService)

    func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        if launchAtLogin {
            try? service.unregister()
        } else {
            try? service.register()
        }
        refreshLaunchAtLoginStatus()
    }

    private func refreshLaunchAtLoginStatus() {
        let status = SMAppService.mainApp.status
        // .enabled == registered to launch at login; anything else we treat as off.
        launchAtLogin = (status == .enabled)
    }
}
