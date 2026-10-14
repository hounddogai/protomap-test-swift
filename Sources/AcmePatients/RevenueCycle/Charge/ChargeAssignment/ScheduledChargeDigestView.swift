import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a scheduled charge digest.
    final class ScheduledChargeDigestView {
        var code: String
        var name: String
        var category: String
        var label: String
        var windowDays: String
        var statusLabel: String

        init(code: String, name: String, category: String, label: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.category = category
            self.label = label
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledChargeDigestView(_ item: ScheduledChargeDigest) -> ScheduledChargeDigestView {
        return ScheduledChargeDigestView(
            code: item.code,
            name: item.name,
            category: item.category,
            label: Kit.Text.truncate(item.label, limit: 120),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledChargeDigestViews(_ items: [ScheduledChargeDigest]) -> [ScheduledChargeDigestView] {
        var views: [ScheduledChargeDigestView] = []
        for item in items {
            views.append(toScheduledChargeDigestView(item))
        }
        return views
    }

    static func sumScheduledChargeDigestView(_ view: ScheduledChargeDigestView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedWindowDays)
    }
}
