import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot override.
    final class SlotOverrideView {
        var code: String
        var title: String
        var visible: String
        var copay: String
        var externalRef: String
        var activeText: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, title: String, visible: String, copay: String, externalRef: String, activeText: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visible = visible
            self.copay = copay
            self.externalRef = externalRef
            self.activeText = activeText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toSlotOverrideView(_ item: SlotOverride) -> SlotOverrideView {
        return SlotOverrideView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            visible: "\(item.visible)",
            copay: String(format: "%.2f", item.copay),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            activeText: "\(item.active)",
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotOverrideViews(_ items: [SlotOverride]) -> [SlotOverrideView] {
        var views: [SlotOverrideView] = []
        for item in items {
            views.append(toSlotOverrideView(item))
        }
        return views
    }

    static func sumSlotOverrideView(_ view: SlotOverrideView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedCopay + Double(parsedExpiresAt)
    }
}
