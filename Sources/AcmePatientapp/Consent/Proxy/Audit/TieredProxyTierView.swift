import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered proxy tier.
    final class TieredProxyTierView {
        var code: String
        var title: String
        var clinicianID: String
        var notes: String
        var approvedText: String
        var windowDays: String
        var priorityText: String
        var maximumText: String
        var limitText: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, notes: String, approvedText: String, windowDays: String, priorityText: String, maximumText: String, limitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.notes = notes
            self.approvedText = approvedText
            self.windowDays = windowDays
            self.priorityText = priorityText
            self.maximumText = maximumText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredProxyTierView(_ item: TieredProxyTier) -> TieredProxyTierView {
        return TieredProxyTierView(
            code: item.code,
            title: item.title,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            notes: item.notes,
            approvedText: "\(item.approved)",
            windowDays: String(item.windowDays),
            priorityText: String(item.priority),
            maximumText: String(format: "%.2f", item.maximum),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredProxyTierViews(_ items: [TieredProxyTier]) -> [TieredProxyTierView] {
        var views: [TieredProxyTierView] = []
        for item in items {
            views.append(toTieredProxyTierView(item))
        }
        return views
    }

    static func sumTieredProxyTierView(_ view: TieredProxyTierView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedPriority) + parsedMaximum
    }
}
