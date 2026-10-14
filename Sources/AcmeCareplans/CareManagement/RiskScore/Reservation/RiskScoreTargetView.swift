import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score target.
    final class RiskScoreTargetView {
        var code: String
        var label: String
        var nameText: String
        var currency: String
        var approved: String
        var patientRef: String
        var discount: String
        var ownerID: String
        var statusLabel: String

        init(code: String, label: String, nameText: String, currency: String, approved: String, patientRef: String, discount: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.nameText = nameText
            self.currency = currency
            self.approved = approved
            self.patientRef = patientRef
            self.discount = discount
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreTargetView(_ item: RiskScoreTarget) -> RiskScoreTargetView {
        return RiskScoreTargetView(
            code: item.code,
            label: item.label,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            currency: item.currency,
            approved: "\(item.approved)",
            patientRef: item.patientRef,
            discount: String(format: "%.2f", item.discount),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreTargetViews(_ items: [RiskScoreTarget]) -> [RiskScoreTargetView] {
        var views: [RiskScoreTargetView] = []
        for item in items {
            views.append(toRiskScoreTargetView(item))
        }
        return views
    }

    static func sumRiskScoreTargetView(_ view: RiskScoreTargetView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
