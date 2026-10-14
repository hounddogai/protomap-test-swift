import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result claim.
    final class ResultClaimView {
        var codeText: String
        var title: String
        var ward: String
        var diagnosisCodeText: String
        var regionText: String
        var quantityText: String
        var statusLabel: String

        init(codeText: String, title: String, ward: String, diagnosisCodeText: String, regionText: String, quantityText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ward = ward
            self.diagnosisCodeText = diagnosisCodeText
            self.regionText = regionText
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toResultClaimView(_ item: ResultClaim) -> ResultClaimView {
        return ResultClaimView(
            codeText: item.code,
            title: item.title,
            ward: item.ward,
            diagnosisCodeText: item.diagnosisCode,
            regionText: item.region,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultClaimViews(_ items: [ResultClaim]) -> [ResultClaimView] {
        var views: [ResultClaimView] = []
        for item in items {
            views.append(toResultClaimView(item))
        }
        return views
    }

    static func sumResultClaimView(_ view: ResultClaimView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
