import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a lenient specimen reservation.
    final class LenientSpecimenReservationView {
        var code: String
        var label: String
        var diagnosisCodeText: String
        var clinicianID: String
        var region: String
        var batchSize: String
        var sequence: String
        var amountText: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCodeText: String, clinicianID: String, region: String, batchSize: String, sequence: String, amountText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCodeText = diagnosisCodeText
            self.clinicianID = clinicianID
            self.region = region
            self.batchSize = batchSize
            self.sequence = sequence
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientSpecimenReservationView(_ item: LenientSpecimenReservation) -> LenientSpecimenReservationView {
        return LenientSpecimenReservationView(
            code: item.code,
            label: item.label,
            diagnosisCodeText: item.diagnosisCode,
            clinicianID: item.clinicianID,
            region: Kit.Text.truncate(item.region, limit: 64),
            batchSize: String(item.batchSize),
            sequence: String(item.sequence),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientSpecimenReservationViews(_ items: [LenientSpecimenReservation]) -> [LenientSpecimenReservationView] {
        var views: [LenientSpecimenReservationView] = []
        for item in items {
            views.append(toLenientSpecimenReservationView(item))
        }
        return views
    }

    static func sumLenientSpecimenReservationView(_ view: LenientSpecimenReservationView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedSequence) + parsedAmount
    }
}
