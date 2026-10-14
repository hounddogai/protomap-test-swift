import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure cycle.
    final class ClosureCycleView {
        var code: String
        var label: String
        var ceilingText: String
        var amount: String
        var regionText: String
        var wardText: String
        var durationMinutes: String
        var endsAt: String
        var reviewerText: String
        var graceDays: String
        var statusLabel: String

        init(code: String, label: String, ceilingText: String, amount: String, regionText: String, wardText: String, durationMinutes: String, endsAt: String, reviewerText: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceilingText = ceilingText
            self.amount = amount
            self.regionText = regionText
            self.wardText = wardText
            self.durationMinutes = durationMinutes
            self.endsAt = endsAt
            self.reviewerText = reviewerText
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toClosureCycleView(_ item: ClosureCycle) -> ClosureCycleView {
        return ClosureCycleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            ceilingText: String(format: "%.2f", item.ceiling),
            amount: String(format: "%.2f", item.amount),
            regionText: item.region,
            wardText: item.ward,
            durationMinutes: String(item.durationMinutes),
            endsAt: String(item.endsAt),
            reviewerText: item.reviewer,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureCycleViews(_ items: [ClosureCycle]) -> [ClosureCycleView] {
        var views: [ClosureCycleView] = []
        for item in items {
            views.append(toClosureCycleView(item))
        }
        return views
    }

    static func sumClosureCycleView(_ view: ClosureCycleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedCeiling + parsedAmount + Double(parsedDurationMinutes)
    }
}
