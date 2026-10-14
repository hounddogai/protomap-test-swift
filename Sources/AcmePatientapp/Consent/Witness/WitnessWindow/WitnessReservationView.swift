import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness reservation.
    final class WitnessReservationView {
        var code: String
        var labelText: String
        var notesText: String
        var ceiling: String
        var discount: String
        var priority: String
        var ownerID: String
        var copay: String
        var ratio: String
        var statusLabel: String

        init(code: String, labelText: String, notesText: String, ceiling: String, discount: String, priority: String, ownerID: String, copay: String, ratio: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.notesText = notesText
            self.ceiling = ceiling
            self.discount = discount
            self.priority = priority
            self.ownerID = ownerID
            self.copay = copay
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessReservationView(_ item: WitnessReservation) -> WitnessReservationView {
        return WitnessReservationView(
            code: item.code,
            labelText: item.label,
            notesText: Kit.Text.truncate(item.notes, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            discount: String(format: "%.2f", item.discount),
            priority: String(item.priority),
            ownerID: item.ownerID,
            copay: String(format: "%.2f", item.copay),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessReservationViews(_ items: [WitnessReservation]) -> [WitnessReservationView] {
        var views: [WitnessReservationView] = []
        for item in items {
            views.append(toWitnessReservationView(item))
        }
        return views
    }

    static func sumWitnessReservationView(_ view: WitnessReservationView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedCeiling + parsedDiscount + Double(parsedPriority)
    }
}
