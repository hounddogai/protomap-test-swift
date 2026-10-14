import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted credential profile.
    final class WeightedCredentialProfileView {
        var code: String
        var nameText: String
        var floorValue: String
        var limit: String
        var quantity: String
        var amount: String
        var statusLabel: String

        init(code: String, nameText: String, floorValue: String, limit: String, quantity: String, amount: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.floorValue = floorValue
            self.limit = limit
            self.quantity = quantity
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCredentialProfileView(_ item: WeightedCredentialProfile) -> WeightedCredentialProfileView {
        return WeightedCredentialProfileView(
            code: item.code,
            nameText: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            limit: String(item.limit),
            quantity: String(item.quantity),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCredentialProfileViews(_ items: [WeightedCredentialProfile]) -> [WeightedCredentialProfileView] {
        var views: [WeightedCredentialProfileView] = []
        for item in items {
            views.append(toWeightedCredentialProfileView(item))
        }
        return views
    }

    static func sumWeightedCredentialProfileView(_ view: WeightedCredentialProfileView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedFloorValue + Double(parsedLimit) + Double(parsedQuantity)
    }
}
