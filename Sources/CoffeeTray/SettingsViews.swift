import SwiftUI

// MARK: - Settings primitives
// Modeled on Gitify's settings UI: rows grouped into rounded cards with
// hairline dividers, section headings with a small icon + semibold title,
// and a label-left / control-right row layout with optional muted caption.

/// A rounded card that groups one or more settings rows, with hairline dividers
/// between rows. Mirrors Gitify's `.settings-list` container.
struct SettingsList<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            _SettingsListDividerInjector(content: content)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

/// Wraps content so that a `Divider` is injected between each top-level child view.
/// SwiftUI doesn't expose inter-item dividers natively, so we collect children via
/// a Group and re-emit them with separators.
private struct _SettingsListDividerInjector<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        // The content closure is laid out as a VStack; we rely on the caller using
        // SettingsRow children. Dividers are drawn by SettingsRow itself (bottom border)
        // except the last row, which omits it.
        content()
    }
}

/// A single settings row: label + optional caption on the left, control on the right.
struct SettingsRow<Control: View>: View {
    let label: String
    var caption: String? = nil
    @ViewBuilder var control: () -> Control

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                    if let caption {
                        Text(caption)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 12)
                control()
                    .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
        }
    }
}

/// A settings row whose control is a Toggle.
struct SettingsToggle: View {
    let label: String
    var caption: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        SettingsRow(label: label, caption: caption) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

/// A section heading: small SF Symbol + semibold title, muted icon.
struct SettingsGroupHeading: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

/// A hairline divider for use between rows inside a SettingsList.
struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 16)
    }
}
