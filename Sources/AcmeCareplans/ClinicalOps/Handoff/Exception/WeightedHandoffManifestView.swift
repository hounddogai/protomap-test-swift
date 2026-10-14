import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted handoff manifest.
    final class WeightedHandoffManifestView {
        var code: String
        var titleText: String
        var bed: String
        var costText: String
        var amount: String
        var statusLabel: String

        init(code: String, titleText: String, bed: String, costText: String, amount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.bed = bed
            self.costText = costText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedHandoffManifestView(_ item: WeightedHandoffManifest) -> WeightedHandoffManifestView {
        return WeightedHandoffManifestView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            bed: item.bed,
            costText: String(format: "%.2f", item.cost),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedHandoffManifestViews(_ items: [WeightedHandoffManifest]) -> [WeightedHandoffManifestView] {
        var views: [WeightedHandoffManifestView] = []
        for item in items {
            views.append(toWeightedHandoffManifestView(item))
        }
        return views
    }

    static func sumWeightedHandoffManifestView(_ view: WeightedHandoffManifestView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedCost + parsedAmount
    }
}
