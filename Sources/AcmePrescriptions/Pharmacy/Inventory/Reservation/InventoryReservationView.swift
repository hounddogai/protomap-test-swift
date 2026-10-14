import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory reservation.
    final class InventoryReservationView {
        var code: String
        var label: String
        var revisionText: String
        var payer: String
        var encounterID: String
        var unit: String
        var rateText: String
        var visible: String
        var segment: String
        var ownerID: String
        var statusLabel: String

        init(code: String, label: String, revisionText: String, payer: String, encounterID: String, unit: String, rateText: String, visible: String, segment: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.revisionText = revisionText
            self.payer = payer
            self.encounterID = encounterID
            self.unit = unit
            self.rateText = rateText
            self.visible = visible
            self.segment = segment
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryReservationView(_ item: InventoryReservation) -> InventoryReservationView {
        return InventoryReservationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            revisionText: String(item.revision),
            payer: item.payer,
            encounterID: item.encounterID,
            unit: Kit.Text.truncate(item.unit, limit: 120),
            rateText: String(format: "%.2f", item.rate),
            visible: "\(item.visible)",
            segment: Kit.Text.truncate(item.segment, limit: 80),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryReservationViews(_ items: [InventoryReservation]) -> [InventoryReservationView] {
        var views: [InventoryReservationView] = []
        for item in items {
            views.append(toInventoryReservationView(item))
        }
        return views
    }

    static func sumInventoryReservationView(_ view: InventoryReservationView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedRevision) + parsedRate
    }
}
