import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted goal digest.
    final class WeightedGoalDigestView {
        var codeText: String
        var nameText: String
        var quantity: String
        var maximum: String
        var source: String
        var reviewerText: String
        var floorValueText: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, nameText: String, quantity: String, maximum: String, source: String, reviewerText: String, floorValueText: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.quantity = quantity
            self.maximum = maximum
            self.source = source
            self.reviewerText = reviewerText
            self.floorValueText = floorValueText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedGoalDigestView(_ item: WeightedGoalDigest) -> WeightedGoalDigestView {
        return WeightedGoalDigestView(
            codeText: item.code,
            nameText: item.name,
            quantity: String(item.quantity),
            maximum: String(format: "%.2f", item.maximum),
            source: item.source,
            reviewerText: item.reviewer,
            floorValueText: String(format: "%.2f", item.floorValue),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedGoalDigestViews(_ items: [WeightedGoalDigest]) -> [WeightedGoalDigestView] {
        var views: [WeightedGoalDigestView] = []
        for item in items {
            views.append(toWeightedGoalDigestView(item))
        }
        return views
    }

    static func sumWeightedGoalDigestView(_ view: WeightedGoalDigestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedQuantity) + parsedMaximum + parsedFloorValue
    }
}
