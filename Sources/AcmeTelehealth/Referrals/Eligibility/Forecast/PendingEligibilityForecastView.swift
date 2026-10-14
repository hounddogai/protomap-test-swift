import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending eligibility forecast.
    final class PendingEligibilityForecastView {
        var code: String
        var label: String
        var cost: String
        var bed: String
        var clinicianIDText: String
        var priority: String
        var graceDays: String
        var statusLabel: String

        init(code: String, label: String, cost: String, bed: String, clinicianIDText: String, priority: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.cost = cost
            self.bed = bed
            self.clinicianIDText = clinicianIDText
            self.priority = priority
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toPendingEligibilityForecastView(_ item: PendingEligibilityForecast) -> PendingEligibilityForecastView {
        return PendingEligibilityForecastView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            cost: String(format: "%.2f", item.cost),
            bed: item.bed,
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 40),
            priority: String(item.priority),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingEligibilityForecastViews(_ items: [PendingEligibilityForecast]) -> [PendingEligibilityForecastView] {
        var views: [PendingEligibilityForecastView] = []
        for item in items {
            views.append(toPendingEligibilityForecastView(item))
        }
        return views
    }

    static func sumPendingEligibilityForecastView(_ view: PendingEligibilityForecastView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedCost + Double(parsedPriority) + Double(parsedGraceDays)
    }
}
