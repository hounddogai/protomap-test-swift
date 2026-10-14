import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict slot batch.
    final class StrictSlotBatchView {
        var code: String
        var label: String
        var clinicianIDText: String
        var unitText: String
        var contactEmail: String
        var ownerID: String
        var quantityText: String
        var statusLabel: String

        init(code: String, label: String, clinicianIDText: String, unitText: String, contactEmail: String, ownerID: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.clinicianIDText = clinicianIDText
            self.unitText = unitText
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSlotBatchView(_ item: StrictSlotBatch) -> StrictSlotBatchView {
        return StrictSlotBatchView(
            code: item.code,
            label: item.label,
            clinicianIDText: item.clinicianID,
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSlotBatchViews(_ items: [StrictSlotBatch]) -> [StrictSlotBatchView] {
        var views: [StrictSlotBatchView] = []
        for item in items {
            views.append(toStrictSlotBatchView(item))
        }
        return views
    }

    static func sumStrictSlotBatchView(_ view: StrictSlotBatchView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
