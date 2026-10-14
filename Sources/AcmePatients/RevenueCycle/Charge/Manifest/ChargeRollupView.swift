import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge rollup.
    final class ChargeRollupView {
        var code: String
        var nameText: String
        var maximumText: String
        var score: String
        var diagnosisCode: String
        var labelText: String
        var approved: String
        var statusLabel: String

        init(code: String, nameText: String, maximumText: String, score: String, diagnosisCode: String, labelText: String, approved: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.maximumText = maximumText
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.labelText = labelText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toChargeRollupView(_ item: ChargeRollup) -> ChargeRollupView {
        return ChargeRollupView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            maximumText: String(format: "%.2f", item.maximum),
            score: String(format: "%.2f", item.score),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            labelText: item.label,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeRollupViews(_ items: [ChargeRollup]) -> [ChargeRollupView] {
        var views: [ChargeRollupView] = []
        for item in items {
            views.append(toChargeRollupView(item))
        }
        return views
    }

    static func sumChargeRollupView(_ view: ChargeRollupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedMaximum + parsedScore
    }
}
