import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set allocation.
    final class OrderSetAllocationView {
        var code: String
        var labelText: String
        var floorValue: String
        var quantity: String
        var source: String
        var checksum: String
        var statusLabel: String

        init(code: String, labelText: String, floorValue: String, quantity: String, source: String, checksum: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.floorValue = floorValue
            self.quantity = quantity
            self.source = source
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetAllocationView(_ item: OrderSetAllocation) -> OrderSetAllocationView {
        return OrderSetAllocationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            quantity: String(item.quantity),
            source: item.source,
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetAllocationViews(_ items: [OrderSetAllocation]) -> [OrderSetAllocationView] {
        var views: [OrderSetAllocationView] = []
        for item in items {
            views.append(toOrderSetAllocationView(item))
        }
        return views
    }

    static func sumOrderSetAllocationView(_ view: OrderSetAllocationView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedFloorValue + Double(parsedQuantity)
    }
}
