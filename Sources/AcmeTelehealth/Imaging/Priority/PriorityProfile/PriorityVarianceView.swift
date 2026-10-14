import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority variance.
    final class PriorityVarianceView {
        var code: String
        var label: String
        var category: String
        var sourceText: String
        var allergy: String
        var payer: String
        var costText: String
        var pinned: String
        var archivedText: String
        var statusLabel: String

        init(code: String, label: String, category: String, sourceText: String, allergy: String, payer: String, costText: String, pinned: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.category = category
            self.sourceText = sourceText
            self.allergy = allergy
            self.payer = payer
            self.costText = costText
            self.pinned = pinned
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityVarianceView(_ item: PriorityVariance) -> PriorityVarianceView {
        return PriorityVarianceView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            category: Kit.Text.truncate(item.category, limit: 64),
            sourceText: item.source,
            allergy: item.allergy,
            payer: item.payer,
            costText: String(format: "%.2f", item.cost),
            pinned: "\(item.pinned)",
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityVarianceViews(_ items: [PriorityVariance]) -> [PriorityVarianceView] {
        var views: [PriorityVarianceView] = []
        for item in items {
            views.append(toPriorityVarianceView(item))
        }
        return views
    }

    static func sumPriorityVarianceView(_ view: PriorityVarianceView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
