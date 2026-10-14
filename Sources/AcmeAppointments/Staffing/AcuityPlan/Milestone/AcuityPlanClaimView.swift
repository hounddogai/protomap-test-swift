import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan claim.
    final class AcuityPlanClaimView {
        var code: String
        var nameText: String
        var payerText: String
        var weight: String
        var dosageMg: String
        var limit: String
        var ownerID: String
        var statusLabel: String

        init(code: String, nameText: String, payerText: String, weight: String, dosageMg: String, limit: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.payerText = payerText
            self.weight = weight
            self.dosageMg = dosageMg
            self.limit = limit
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanClaimView(_ item: AcuityPlanClaim) -> AcuityPlanClaimView {
        return AcuityPlanClaimView(
            code: item.code,
            nameText: item.name,
            payerText: item.payer,
            weight: String(format: "%.2f", item.weight),
            dosageMg: String(format: "%.2f", item.dosageMg),
            limit: String(item.limit),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanClaimViews(_ items: [AcuityPlanClaim]) -> [AcuityPlanClaimView] {
        var views: [AcuityPlanClaimView] = []
        for item in items {
            views.append(toAcuityPlanClaimView(item))
        }
        return views
    }

    static func sumAcuityPlanClaimView(_ view: AcuityPlanClaimView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedWeight + parsedDosageMg + Double(parsedLimit)
    }
}
