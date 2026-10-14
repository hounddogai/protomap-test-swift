import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending recall allocation.
    final class PendingRecallAllocationView {
        var code: String
        var name: String
        var quantity: String
        var cost: String
        var categoryText: String
        var copay: String
        var statusLabel: String

        init(code: String, name: String, quantity: String, cost: String, categoryText: String, copay: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.cost = cost
            self.categoryText = categoryText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRecallAllocationView(_ item: PendingRecallAllocation) -> PendingRecallAllocationView {
        return PendingRecallAllocationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 80),
            quantity: String(item.quantity),
            cost: String(format: "%.2f", item.cost),
            categoryText: item.category,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRecallAllocationViews(_ items: [PendingRecallAllocation]) -> [PendingRecallAllocationView] {
        var views: [PendingRecallAllocationView] = []
        for item in items {
            views.append(toPendingRecallAllocationView(item))
        }
        return views
    }

    static func sumPendingRecallAllocationView(_ view: PendingRecallAllocationView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedQuantity) + parsedCost + parsedCopay
    }
}
