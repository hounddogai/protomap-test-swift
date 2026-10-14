import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation reservation.
    final class RevocationReservationView {
        var code: String
        var label: String
        var allergy: String
        var endsAtText: String
        var diagnosisCode: String
        var batchSize: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, allergy: String, endsAtText: String, diagnosisCode: String, batchSize: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.endsAtText = endsAtText
            self.diagnosisCode = diagnosisCode
            self.batchSize = batchSize
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationReservationView(_ item: RevocationReservation) -> RevocationReservationView {
        return RevocationReservationView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            allergy: item.allergy,
            endsAtText: String(item.endsAt),
            diagnosisCode: item.diagnosisCode,
            batchSize: String(item.batchSize),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationReservationViews(_ items: [RevocationReservation]) -> [RevocationReservationView] {
        var views: [RevocationReservationView] = []
        for item in items {
            views.append(toRevocationReservationView(item))
        }
        return views
    }

    static func sumRevocationReservationView(_ view: RevocationReservationView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedBatchSize)
    }
}
