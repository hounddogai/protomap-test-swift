import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory slot.
    final class InventorySlotView {
        var codeText: String
        var title: String
        var clinicianID: String
        var channel: String
        var visibleText: String
        var quantity: String
        var payer: String
        var statusLabel: String

        init(codeText: String, title: String, clinicianID: String, channel: String, visibleText: String, quantity: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.clinicianID = clinicianID
            self.channel = channel
            self.visibleText = visibleText
            self.quantity = quantity
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toInventorySlotView(_ item: InventorySlot) -> InventorySlotView {
        return InventorySlotView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            clinicianID: item.clinicianID,
            channel: item.channel,
            visibleText: "\(item.visible)",
            quantity: String(item.quantity),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventorySlotViews(_ items: [InventorySlot]) -> [InventorySlotView] {
        var views: [InventorySlotView] = []
        for item in items {
            views.append(toInventorySlotView(item))
        }
        return views
    }

    static func sumInventorySlotView(_ view: InventorySlotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
