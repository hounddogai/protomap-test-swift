import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default remittance reservation.
    final class DefaultRemittanceReservationView {
        var code: String
        var title: String
        var pinned: String
        var diagnosisCode: String
        var clinicianIDText: String
        var dosageMgText: String
        var reviewer: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, title: String, pinned: String, diagnosisCode: String, clinicianIDText: String, dosageMgText: String, reviewer: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.diagnosisCode = diagnosisCode
            self.clinicianIDText = clinicianIDText
            self.dosageMgText = dosageMgText
            self.reviewer = reviewer
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRemittanceReservationView(_ item: DefaultRemittanceReservation) -> DefaultRemittanceReservationView {
        return DefaultRemittanceReservationView(
            code: item.code,
            title: item.title,
            pinned: "\(item.pinned)",
            diagnosisCode: item.diagnosisCode,
            clinicianIDText: item.clinicianID,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            reviewer: item.reviewer,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRemittanceReservationViews(_ items: [DefaultRemittanceReservation]) -> [DefaultRemittanceReservationView] {
        var views: [DefaultRemittanceReservationView] = []
        for item in items {
            views.append(toDefaultRemittanceReservationView(item))
        }
        return views
    }

    static func sumDefaultRemittanceReservationView(_ view: DefaultRemittanceReservationView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedDosageMg + Double(parsedExpiresAt)
    }
}
