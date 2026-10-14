import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a pending rounding plan.
    final class PendingRoundingPlanView {
        var code: String
        var title: String
        var unit: String
        var pinned: String
        var graceDays: String
        var facility: String
        var source: String
        var countryText: String
        var threshold: String
        var payer: String
        var statusLabel: String

        init(code: String, title: String, unit: String, pinned: String, graceDays: String, facility: String, source: String, countryText: String, threshold: String, payer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.unit = unit
            self.pinned = pinned
            self.graceDays = graceDays
            self.facility = facility
            self.source = source
            self.countryText = countryText
            self.threshold = threshold
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRoundingPlanView(_ item: PendingRoundingPlan) -> PendingRoundingPlanView {
        return PendingRoundingPlanView(
            code: item.code,
            title: item.title,
            unit: item.unit,
            pinned: "\(item.pinned)",
            graceDays: String(item.graceDays),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            source: Kit.Text.truncate(item.source, limit: 120),
            countryText: item.country,
            threshold: String(format: "%.2f", item.threshold),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRoundingPlanViews(_ items: [PendingRoundingPlan]) -> [PendingRoundingPlanView] {
        var views: [PendingRoundingPlanView] = []
        for item in items {
            views.append(toPendingRoundingPlanView(item))
        }
        return views
    }

    static func sumPendingRoundingPlanView(_ view: PendingRoundingPlanView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedGraceDays) + parsedThreshold
    }
}
