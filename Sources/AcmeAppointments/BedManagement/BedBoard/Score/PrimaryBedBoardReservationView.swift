import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary bed board reservation.
    final class PrimaryBedBoardReservationView {
        var code: String
        var nameText: String
        var specialty: String
        var currency: String
        var attempts: String
        var weightText: String
        var batchSize: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, nameText: String, specialty: String, currency: String, attempts: String, weightText: String, batchSize: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.specialty = specialty
            self.currency = currency
            self.attempts = attempts
            self.weightText = weightText
            self.batchSize = batchSize
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryBedBoardReservationView(_ item: PrimaryBedBoardReservation) -> PrimaryBedBoardReservationView {
        return PrimaryBedBoardReservationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            specialty: item.specialty,
            currency: item.currency,
            attempts: String(item.attempts),
            weightText: String(format: "%.2f", item.weight),
            batchSize: String(item.batchSize),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryBedBoardReservationViews(_ items: [PrimaryBedBoardReservation]) -> [PrimaryBedBoardReservationView] {
        var views: [PrimaryBedBoardReservationView] = []
        for item in items {
            views.append(toPrimaryBedBoardReservationView(item))
        }
        return views
    }

    static func sumPrimaryBedBoardReservationView(_ view: PrimaryBedBoardReservationView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedAttempts) + parsedWeight + Double(parsedBatchSize)
    }
}
