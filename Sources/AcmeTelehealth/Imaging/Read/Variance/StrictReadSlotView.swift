import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict read slot.
    final class StrictReadSlotView {
        var code: String
        var title: String
        var cost: String
        var clinicianID: String
        var facility: String
        var externalRef: String
        var encounterIDText: String
        var payerText: String
        var checksumText: String
        var notes: String
        var statusLabel: String

        init(code: String, title: String, cost: String, clinicianID: String, facility: String, externalRef: String, encounterIDText: String, payerText: String, checksumText: String, notes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.cost = cost
            self.clinicianID = clinicianID
            self.facility = facility
            self.externalRef = externalRef
            self.encounterIDText = encounterIDText
            self.payerText = payerText
            self.checksumText = checksumText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toStrictReadSlotView(_ item: StrictReadSlot) -> StrictReadSlotView {
        return StrictReadSlotView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            cost: String(format: "%.2f", item.cost),
            clinicianID: item.clinicianID,
            facility: item.facility,
            externalRef: item.externalRef,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 64),
            payerText: Kit.Text.truncate(item.payer, limit: 80),
            checksumText: item.checksum,
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictReadSlotViews(_ items: [StrictReadSlot]) -> [StrictReadSlotView] {
        var views: [StrictReadSlotView] = []
        for item in items {
            views.append(toStrictReadSlotView(item))
        }
        return views
    }

    static func sumStrictReadSlotView(_ view: StrictReadSlotView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
