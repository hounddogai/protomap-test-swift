import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a weighted discharge plan summary.
    final class WeightedDischargePlanSummaryView {
        var code: String
        var name: String
        var attempts: String
        var payer: String
        var dosageMgText: String
        var threshold: String
        var statusLabel: String

        init(code: String, name: String, attempts: String, payer: String, dosageMgText: String, threshold: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.payer = payer
            self.dosageMgText = dosageMgText
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedDischargePlanSummaryView(_ item: WeightedDischargePlanSummary) -> WeightedDischargePlanSummaryView {
        return WeightedDischargePlanSummaryView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            attempts: String(item.attempts),
            payer: item.payer,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedDischargePlanSummaryViews(_ items: [WeightedDischargePlanSummary]) -> [WeightedDischargePlanSummaryView] {
        var views: [WeightedDischargePlanSummaryView] = []
        for item in items {
            views.append(toWeightedDischargePlanSummaryView(item))
        }
        return views
    }

    static func sumWeightedDischargePlanSummaryView(_ view: WeightedDischargePlanSummaryView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedAttempts) + parsedDosageMg + parsedThreshold
    }
}
