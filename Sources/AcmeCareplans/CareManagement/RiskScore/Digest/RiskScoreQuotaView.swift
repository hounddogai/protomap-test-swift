import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score quota.
    final class RiskScoreQuotaView {
        var code: String
        var label: String
        var scoreText: String
        var approved: String
        var patientRefText: String
        var visible: String
        var discountText: String
        var statusLabel: String

        init(code: String, label: String, scoreText: String, approved: String, patientRefText: String, visible: String, discountText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.scoreText = scoreText
            self.approved = approved
            self.patientRefText = patientRefText
            self.visible = visible
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreQuotaView(_ item: RiskScoreQuota) -> RiskScoreQuotaView {
        return RiskScoreQuotaView(
            code: item.code,
            label: item.label,
            scoreText: String(format: "%.2f", item.score),
            approved: "\(item.approved)",
            patientRefText: item.patientRef,
            visible: "\(item.visible)",
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreQuotaViews(_ items: [RiskScoreQuota]) -> [RiskScoreQuotaView] {
        var views: [RiskScoreQuotaView] = []
        for item in items {
            views.append(toRiskScoreQuotaView(item))
        }
        return views
    }

    static func sumRiskScoreQuotaView(_ view: RiskScoreQuotaView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedScore + parsedDiscount
    }
}
