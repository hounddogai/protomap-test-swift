import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched cleaning cycle.
    final class BatchedCleaningCycleView {
        var code: String
        var titleText: String
        var categoryText: String
        var maximumText: String
        var priorityText: String
        var pinned: String
        var currency: String
        var statusLabel: String

        init(code: String, titleText: String, categoryText: String, maximumText: String, priorityText: String, pinned: String, currency: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.categoryText = categoryText
            self.maximumText = maximumText
            self.priorityText = priorityText
            self.pinned = pinned
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCleaningCycleView(_ item: BatchedCleaningCycle) -> BatchedCleaningCycleView {
        return BatchedCleaningCycleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            categoryText: item.category,
            maximumText: String(format: "%.2f", item.maximum),
            priorityText: String(item.priority),
            pinned: "\(item.pinned)",
            currency: Kit.Text.truncate(item.currency, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCleaningCycleViews(_ items: [BatchedCleaningCycle]) -> [BatchedCleaningCycleView] {
        var views: [BatchedCleaningCycleView] = []
        for item in items {
            views.append(toBatchedCleaningCycleView(item))
        }
        return views
    }

    static func sumBatchedCleaningCycleView(_ view: BatchedCleaningCycleView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedMaximum + Double(parsedPriority)
    }
}
