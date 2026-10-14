import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional revocation estimate.
    final class RegionalRevocationEstimateView {
        var codeText: String
        var titleText: String
        var diagnosisCode: String
        var region: String
        var acuity: String
        var quantityText: String
        var categoryText: String
        var facility: String
        var statusLabel: String

        init(codeText: String, titleText: String, diagnosisCode: String, region: String, acuity: String, quantityText: String, categoryText: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.diagnosisCode = diagnosisCode
            self.region = region
            self.acuity = acuity
            self.quantityText = quantityText
            self.categoryText = categoryText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRevocationEstimateView(_ item: RegionalRevocationEstimate) -> RegionalRevocationEstimateView {
        return RegionalRevocationEstimateView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            diagnosisCode: item.diagnosisCode,
            region: Kit.Text.truncate(item.region, limit: 80),
            acuity: String(item.acuity),
            quantityText: String(item.quantity),
            categoryText: item.category,
            facility: Kit.Text.truncate(item.facility, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRevocationEstimateViews(_ items: [RegionalRevocationEstimate]) -> [RegionalRevocationEstimateView] {
        var views: [RegionalRevocationEstimateView] = []
        for item in items {
            views.append(toRegionalRevocationEstimateView(item))
        }
        return views
    }

    static func sumRegionalRevocationEstimateView(_ view: RegionalRevocationEstimateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedAcuity) + Double(parsedQuantity)
    }
}
