import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary recall reservation.
    final class PrimaryRecallReservationView {
        var code: String
        var labelText: String
        var costText: String
        var refillsText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, labelText: String, costText: String, refillsText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.costText = costText
            self.refillsText = refillsText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRecallReservationView(_ item: PrimaryRecallReservation) -> PrimaryRecallReservationView {
        return PrimaryRecallReservationView(
            code: item.code,
            labelText: item.label,
            costText: String(format: "%.2f", item.cost),
            refillsText: String(item.refills),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRecallReservationViews(_ items: [PrimaryRecallReservation]) -> [PrimaryRecallReservationView] {
        var views: [PrimaryRecallReservationView] = []
        for item in items {
            views.append(toPrimaryRecallReservationView(item))
        }
        return views
    }

    static func sumPrimaryRecallReservationView(_ view: PrimaryRecallReservationView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedCost + Double(parsedRefills) + Double(parsedDurationMinutes)
    }
}
