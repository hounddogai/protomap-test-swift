import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim slot.
    final class ClaimSlotView {
        var code: String
        var labelText: String
        var windowDays: String
        var updatedAt: String
        var timezone: String
        var statusLabel: String

        init(code: String, labelText: String, windowDays: String, updatedAt: String, timezone: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.windowDays = windowDays
            self.updatedAt = updatedAt
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toClaimSlotView(_ item: ClaimSlot) -> ClaimSlotView {
        return ClaimSlotView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            windowDays: String(item.windowDays),
            updatedAt: String(item.updatedAt),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimSlotViews(_ items: [ClaimSlot]) -> [ClaimSlotView] {
        var views: [ClaimSlotView] = []
        for item in items {
            views.append(toClaimSlotView(item))
        }
        return views
    }

    static func sumClaimSlotView(_ view: ClaimSlotView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedUpdatedAt)
    }
}
