import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a manual rounding budget.
    final class ManualRoundingBudgetView {
        var code: String
        var title: String
        var floorValue: String
        var archived: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, title: String, floorValue: String, archived: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.archived = archived
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toManualRoundingBudgetView(_ item: ManualRoundingBudget) -> ManualRoundingBudgetView {
        return ManualRoundingBudgetView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            archived: "\(item.archived)",
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRoundingBudgetViews(_ items: [ManualRoundingBudget]) -> [ManualRoundingBudgetView] {
        var views: [ManualRoundingBudgetView] = []
        for item in items {
            views.append(toManualRoundingBudgetView(item))
        }
        return views
    }

    static func sumManualRoundingBudgetView(_ view: ManualRoundingBudgetView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedFloorValue + Double(parsedVisitMinutes)
    }
}
