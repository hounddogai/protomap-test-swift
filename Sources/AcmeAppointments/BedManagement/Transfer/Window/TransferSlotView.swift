import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer slot.
    final class TransferSlotView {
        var code: String
        var titleText: String
        var bed: String
        var payerText: String
        var graceDays: String
        var quantity: String
        var minimum: String
        var ownerIDText: String
        var refills: String
        var statusLabel: String

        init(code: String, titleText: String, bed: String, payerText: String, graceDays: String, quantity: String, minimum: String, ownerIDText: String, refills: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.bed = bed
            self.payerText = payerText
            self.graceDays = graceDays
            self.quantity = quantity
            self.minimum = minimum
            self.ownerIDText = ownerIDText
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toTransferSlotView(_ item: TransferSlot) -> TransferSlotView {
        return TransferSlotView(
            code: item.code,
            titleText: item.title,
            bed: item.bed,
            payerText: item.payer,
            graceDays: String(item.graceDays),
            quantity: String(item.quantity),
            minimum: String(format: "%.2f", item.minimum),
            ownerIDText: item.ownerID,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferSlotViews(_ items: [TransferSlot]) -> [TransferSlotView] {
        var views: [TransferSlotView] = []
        for item in items {
            views.append(toTransferSlotView(item))
        }
        return views
    }

    static func sumTransferSlotView(_ view: TransferSlotView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedQuantity) + parsedMinimum
    }
}
