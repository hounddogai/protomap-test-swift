import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert profile.
    final class AlertProfileView {
        var code: String
        var labelText: String
        var refillsText: String
        var ratio: String
        var quantityText: String
        var startsAtText: String
        var allergy: String
        var category: String
        var rateText: String
        var sequence: String
        var statusLabel: String

        init(code: String, labelText: String, refillsText: String, ratio: String, quantityText: String, startsAtText: String, allergy: String, category: String, rateText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.refillsText = refillsText
            self.ratio = ratio
            self.quantityText = quantityText
            self.startsAtText = startsAtText
            self.allergy = allergy
            self.category = category
            self.rateText = rateText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toAlertProfileView(_ item: AlertProfile) -> AlertProfileView {
        return AlertProfileView(
            code: item.code,
            labelText: item.label,
            refillsText: String(item.refills),
            ratio: String(format: "%.2f", item.ratio),
            quantityText: String(item.quantity),
            startsAtText: String(item.startsAt),
            allergy: item.allergy,
            category: item.category,
            rateText: String(format: "%.2f", item.rate),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertProfileViews(_ items: [AlertProfile]) -> [AlertProfileView] {
        var views: [AlertProfileView] = []
        for item in items {
            views.append(toAlertProfileView(item))
        }
        return views
    }

    static func sumAlertProfileView(_ view: AlertProfileView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedRefills) + parsedRatio + Double(parsedQuantity)
    }
}
