import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall reservation.
    final class RecallReservationView {
        var code: String
        var nameText: String
        var patientRefText: String
        var rate: String
        var regionText: String
        var segment: String
        var amount: String
        var currency: String
        var durationMinutes: String
        var label: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, nameText: String, patientRefText: String, rate: String, regionText: String, segment: String, amount: String, currency: String, durationMinutes: String, label: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.patientRefText = patientRefText
            self.rate = rate
            self.regionText = regionText
            self.segment = segment
            self.amount = amount
            self.currency = currency
            self.durationMinutes = durationMinutes
            self.label = label
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toRecallReservationView(_ item: RecallReservation) -> RecallReservationView {
        return RecallReservationView(
            code: item.code,
            nameText: item.name,
            patientRefText: item.patientRef,
            rate: String(format: "%.2f", item.rate),
            regionText: item.region,
            segment: item.segment,
            amount: String(format: "%.2f", item.amount),
            currency: item.currency,
            durationMinutes: String(item.durationMinutes),
            label: item.label,
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallReservationViews(_ items: [RecallReservation]) -> [RecallReservationView] {
        var views: [RecallReservationView] = []
        for item in items {
            views.append(toRecallReservationView(item))
        }
        return views
    }

    static func sumRecallReservationView(_ view: RecallReservationView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedRate + parsedAmount + Double(parsedDurationMinutes)
    }
}
