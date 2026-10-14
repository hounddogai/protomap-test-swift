import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal batch.
    final class GoalBatchView {
        var codeText: String
        var title: String
        var floorValue: String
        var currency: String
        var revision: String
        var quantityText: String
        var summary: String
        var visitMinutes: String
        var visible: String
        var statusLabel: String

        init(codeText: String, title: String, floorValue: String, currency: String, revision: String, quantityText: String, summary: String, visitMinutes: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.floorValue = floorValue
            self.currency = currency
            self.revision = revision
            self.quantityText = quantityText
            self.summary = summary
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toGoalBatchView(_ item: GoalBatch) -> GoalBatchView {
        return GoalBatchView(
            codeText: item.code,
            title: item.title,
            floorValue: String(format: "%.2f", item.floorValue),
            currency: Kit.Text.truncate(item.currency, limit: 64),
            revision: String(item.revision),
            quantityText: String(item.quantity),
            summary: item.summary,
            visitMinutes: String(item.visitMinutes),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalBatchViews(_ items: [GoalBatch]) -> [GoalBatchView] {
        var views: [GoalBatchView] = []
        for item in items {
            views.append(toGoalBatchView(item))
        }
        return views
    }

    static func sumGoalBatchView(_ view: GoalBatchView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedFloorValue + Double(parsedRevision) + Double(parsedQuantity)
    }
}
