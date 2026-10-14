import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range budget.
    final class ReferenceRangeBudgetView {
        var code: String
        var label: String
        var batchSize: String
        var ratioText: String
        var ward: String
        var category: String
        var limit: String
        var archived: String
        var statusLabel: String

        init(code: String, label: String, batchSize: String, ratioText: String, ward: String, category: String, limit: String, archived: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.ratioText = ratioText
            self.ward = ward
            self.category = category
            self.limit = limit
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeBudgetView(_ item: ReferenceRangeBudget) -> ReferenceRangeBudgetView {
        return ReferenceRangeBudgetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            batchSize: String(item.batchSize),
            ratioText: String(format: "%.2f", item.ratio),
            ward: item.ward,
            category: item.category,
            limit: String(item.limit),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeBudgetViews(_ items: [ReferenceRangeBudget]) -> [ReferenceRangeBudgetView] {
        var views: [ReferenceRangeBudgetView] = []
        for item in items {
            views.append(toReferenceRangeBudgetView(item))
        }
        return views
    }

    static func sumReferenceRangeBudgetView(_ view: ReferenceRangeBudgetView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedBatchSize) + parsedRatio + Double(parsedLimit)
    }
}
