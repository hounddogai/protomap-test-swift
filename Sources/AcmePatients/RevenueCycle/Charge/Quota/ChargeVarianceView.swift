import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge variance.
    final class ChargeVarianceView {
        var code: String
        var title: String
        var threshold: String
        var priority: String
        var active: String
        var windowDaysText: String
        var pinnedText: String
        var createdAt: String
        var costText: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, title: String, threshold: String, priority: String, active: String, windowDaysText: String, pinnedText: String, createdAt: String, costText: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.priority = priority
            self.active = active
            self.windowDaysText = windowDaysText
            self.pinnedText = pinnedText
            self.createdAt = createdAt
            self.costText = costText
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toChargeVarianceView(_ item: ChargeVariance) -> ChargeVarianceView {
        return ChargeVarianceView(
            code: item.code,
            title: item.title,
            threshold: String(format: "%.2f", item.threshold),
            priority: String(item.priority),
            active: "\(item.active)",
            windowDaysText: String(item.windowDays),
            pinnedText: "\(item.pinned)",
            createdAt: String(item.createdAt),
            costText: String(format: "%.2f", item.cost),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeVarianceViews(_ items: [ChargeVariance]) -> [ChargeVarianceView] {
        var views: [ChargeVarianceView] = []
        for item in items {
            views.append(toChargeVarianceView(item))
        }
        return views
    }

    static func sumChargeVarianceView(_ view: ChargeVarianceView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedThreshold + Double(parsedPriority) + Double(parsedWindowDays)
    }
}
