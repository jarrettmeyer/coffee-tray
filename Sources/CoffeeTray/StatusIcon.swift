import AppKit

/// Renders the coffee-cup icon to an NSImage for the status item.
///
/// Emoji glyphs render as full-color bitmaps that ignore `.foregroundColor`, so
/// we can't just draw the emoji in gray for the idle state. Instead we draw the
/// full-color emoji and then blend it toward the menu-bar background color by
/// overlaying that color at reduced alpha — producing a clearly faded, washed-out
/// look without going pitch black (which template mode causes).
///
/// - `active == true`  → full-color emoji.
/// - `active == false` → emoji blended toward the menu background.
enum StatusIcon {

    /// Alpha of the background overlay for the idle state. 0.0 = full color,
    /// 1.0 = fully background-colored (invisible). 0.6 reads as clearly dimmed.
    private static let idleOverlayAlpha: CGFloat = 0.6

    static func image(active: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let emoji = renderEmoji()

        if active {
            return emoji
        }

        // Blend the emoji toward the menu-bar background color for a faded look.
        let image = NSImage(size: size)
        image.lockFocus()

        // 1. Draw the full-color emoji.
        emoji.draw(in: NSRect(origin: .zero, size: size))

        // 2. Overdraw the background color at reduced alpha to wash it out.
        let bg = NSColor.windowBackgroundColor.withAlphaComponent(idleOverlayAlpha)
        bg.setFill()
        NSRect(origin: .zero, size: size).fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    /// Render the ☕ emoji to an NSImage at status-item size.
    private static func renderEmoji() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14)
        ]
        let str = NSAttributedString(string: "☕", attributes: attrs)
        let textSize = str.size()
        let origin = NSPoint(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2
        )
        str.draw(at: origin)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
