import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched panel profile.
    final class BatchedPanelProfileView {
        var code: String
        var titleText: String
        var discountText: String
        var copay: String
        var budget: String
        var floorValueText: String
        var description: String
        var statusLabel: String

        init(code: String, titleText: String, discountText: String, copay: String, budget: String, floorValueText: String, description: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.discountText = discountText
            self.copay = copay
            self.budget = budget
            self.floorValueText = floorValueText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedPanelProfileView(_ item: BatchedPanelProfile) -> BatchedPanelProfileView {
        return BatchedPanelProfileView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            discountText: String(format: "%.2f", item.discount),
            copay: String(format: "%.2f", item.copay),
            budget: String(format: "%.2f", item.budget),
            floorValueText: String(format: "%.2f", item.floorValue),
            description: Kit.Text.truncate(item.description, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedPanelProfileViews(_ items: [BatchedPanelProfile]) -> [BatchedPanelProfileView] {
        var views: [BatchedPanelProfileView] = []
        for item in items {
            views.append(toBatchedPanelProfileView(item))
        }
        return views
    }

    static func sumBatchedPanelProfileView(_ view: BatchedPanelProfileView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedDiscount + parsedCopay + parsedBudget
    }
}
