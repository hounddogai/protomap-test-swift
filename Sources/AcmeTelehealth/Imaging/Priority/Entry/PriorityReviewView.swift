import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority review.
    final class PriorityReviewView {
        var codeText: String
        var name: String
        var category: String
        var visible: String
        var ceiling: String
        var batchSize: String
        var statusLabel: String

        init(codeText: String, name: String, category: String, visible: String, ceiling: String, batchSize: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.category = category
            self.visible = visible
            self.ceiling = ceiling
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityReviewView(_ item: PriorityReview) -> PriorityReviewView {
        return PriorityReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            category: item.category,
            visible: "\(item.visible)",
            ceiling: String(format: "%.2f", item.ceiling),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityReviewViews(_ items: [PriorityReview]) -> [PriorityReviewView] {
        var views: [PriorityReviewView] = []
        for item in items {
            views.append(toPriorityReviewView(item))
        }
        return views
    }

    static func sumPriorityReviewView(_ view: PriorityReviewView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCeiling + Double(parsedBatchSize)
    }
}
