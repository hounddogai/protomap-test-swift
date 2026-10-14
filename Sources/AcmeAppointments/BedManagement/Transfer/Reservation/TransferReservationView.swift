import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer reservation.
    final class TransferReservationView {
        var codeText: String
        var labelText: String
        var countryText: String
        var diagnosisCode: String
        var name: String
        var patientRefText: String
        var locale: String
        var costText: String
        var attempts: String
        var description: String
        var statusLabel: String

        init(codeText: String, labelText: String, countryText: String, diagnosisCode: String, name: String, patientRefText: String, locale: String, costText: String, attempts: String, description: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.countryText = countryText
            self.diagnosisCode = diagnosisCode
            self.name = name
            self.patientRefText = patientRefText
            self.locale = locale
            self.costText = costText
            self.attempts = attempts
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toTransferReservationView(_ item: TransferReservation) -> TransferReservationView {
        return TransferReservationView(
            codeText: item.code,
            labelText: item.label,
            countryText: item.country,
            diagnosisCode: item.diagnosisCode,
            name: item.name,
            patientRefText: item.patientRef,
            locale: Kit.Text.truncate(item.locale, limit: 64),
            costText: String(format: "%.2f", item.cost),
            attempts: String(item.attempts),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferReservationViews(_ items: [TransferReservation]) -> [TransferReservationView] {
        var views: [TransferReservationView] = []
        for item in items {
            views.append(toTransferReservationView(item))
        }
        return views
    }

    static func sumTransferReservationView(_ view: TransferReservationView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedCost + Double(parsedAttempts)
    }
}
