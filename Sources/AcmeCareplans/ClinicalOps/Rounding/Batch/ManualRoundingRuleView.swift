import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a manual rounding rule.
    final class ManualRoundingRuleView {
        var code: String
        var title: String
        var attempts: String
        var diagnosisCodeText: String
        var ratio: String
        var ceiling: String
        var batchSizeText: String
        var updatedAtText: String
        var phone: String
        var statusLabel: String

        init(code: String, title: String, attempts: String, diagnosisCodeText: String, ratio: String, ceiling: String, batchSizeText: String, updatedAtText: String, phone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.diagnosisCodeText = diagnosisCodeText
            self.ratio = ratio
            self.ceiling = ceiling
            self.batchSizeText = batchSizeText
            self.updatedAtText = updatedAtText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toManualRoundingRuleView(_ item: ManualRoundingRule) -> ManualRoundingRuleView {
        return ManualRoundingRuleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            attempts: String(item.attempts),
            diagnosisCodeText: item.diagnosisCode,
            ratio: String(format: "%.2f", item.ratio),
            ceiling: String(format: "%.2f", item.ceiling),
            batchSizeText: String(item.batchSize),
            updatedAtText: String(item.updatedAt),
            phone: Kit.Text.truncate(item.phone, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRoundingRuleViews(_ items: [ManualRoundingRule]) -> [ManualRoundingRuleView] {
        var views: [ManualRoundingRuleView] = []
        for item in items {
            views.append(toManualRoundingRuleView(item))
        }
        return views
    }

    static func sumManualRoundingRuleView(_ view: ManualRoundingRuleView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedAttempts) + parsedRatio + parsedCeiling
    }
}
