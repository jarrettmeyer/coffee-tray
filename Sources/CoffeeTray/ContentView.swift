import SwiftUI
import AppKit

/// Compact settings UI hosted in the menu-bar popover, styled after Gitify's
/// settings page: grouped rows in rounded cards, section headings with icons,
/// label-left / control-right rows, segmented controls for picks.
///
/// All controls bind to `CaffeinateController`; flag/timeout edits while caffeinate
/// is running trigger a restart via `restartIfRunning()` so changes take effect
/// immediately.
struct ContentView: View {

    @ObservedObject var controller: CaffeinateController

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerSection
                statusSection
                flagsSection
                timeoutSection
                optionsSection
                quitSection
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .frame(width: 320, height: 440)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 28, height: 28)
            Text("Coffee Tray")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Text(appVersion)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return v.map { "v\($0)" } ?? ""
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 0) {
            SettingsList {
                SettingsToggle(
                    label: "Caffeinate",
                    caption: controller.isOn ? "Running" : "Idle",
                    isOn: $controller.isOn
                )
                .onChange(of: controller.isOn) { newValue in
                    if newValue { controller.start() } else { controller.stop() }
                }
            }
        }
    }

    // MARK: - Flags

    private var flagsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsGroupHeading(systemImage: "moon.zzz", title: "Sleep Prevention")
            SettingsList {
                SettingsToggle(label: "Prevent display sleep", isOn: $controller.flagD)
                    .onChange(of: controller.flagD) { _ in controller.restartIfRunning() }
                SettingsDivider()
                SettingsToggle(label: "Prevent idle sleep", isOn: $controller.flagI)
                    .onChange(of: controller.flagI) { _ in controller.restartIfRunning() }
                SettingsDivider()
                SettingsToggle(label: "Prevent system sleep",
                                caption: "AC power only",
                                isOn: $controller.flagS)
                    .onChange(of: controller.flagS) { _ in controller.restartIfRunning() }
                SettingsDivider()
                SettingsToggle(
                    label: "Declare user active",
                    caption: "Turns the display on and keeps it awake",
                    isOn: $controller.flagU
                )
                .onChange(of: controller.flagU) { _ in controller.restartIfRunning() }
            }
        }
    }

    // MARK: - Timeout

    private var timeoutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsGroupHeading(systemImage: "timer", title: "Timeout")
            SettingsList {
                SettingsRow(label: "Mode") {
                    Picker("", selection: $controller.timeoutMode) {
                        Text("Off").tag(CaffeinateController.TimeoutMode.off)
                        Text("Until").tag(CaffeinateController.TimeoutMode.until)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: controller.timeoutMode) { _ in
                        controller.restartIfRunning()
                    }
                }

                switch controller.timeoutMode {
                case .off:
                    EmptyView()
                case .until:
                    SettingsDivider()
                    SettingsRow(label: "Stop at") {
                        DatePicker(
                            "",
                            selection: $controller.targetDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.field)
                        .labelsHidden()
                        .onChange(of: controller.targetDate) { _ in
                            controller.restartIfRunning()
                        }
                    }
                    if controller.targetDate <= Date() {
                        SettingsDivider()
                        SettingsRow(label: "", caption: "Pick a future time.") {
                            EmptyView()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Options

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsGroupHeading(systemImage: "gearshape", title: "Options")
            SettingsList {
                SettingsToggle(label: "Launch at Login",
                                caption: "Start when you log in",
                                isOn: Binding(
                                    get: { controller.launchAtLogin },
                                    set: { _ in controller.toggleLaunchAtLogin() }
                                ))
            }
        }
    }

    // MARK: - Quit

    private var quitSection: some View {
        SettingsList {
            SettingsRow(label: "") {
                Button("Quit Coffee Tray", role: .destructive) {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 13, weight: .medium))
            }
        }
    }
}
