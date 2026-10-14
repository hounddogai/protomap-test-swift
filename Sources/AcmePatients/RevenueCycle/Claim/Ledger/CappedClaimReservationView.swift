import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped claim reservation.
    final class CappedClaimReservationView {
        var code: String
        var labelText: String
        var currency: String
        var payer: String
        var amount: String
        var diagnosisCodeText: String
        var checksum: String
        var locale: String
        var ceiling: String
        var encounterID: String
        var statusLabel: String

        init(code: String, labelText: String, currency: String, payer: String, amount: String, diagnosisCodeText: String, checksum: String, locale: String, ceiling: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.currency = currency
            self.payer = payer
            self.amount = amount
            self.diagnosisCodeText = diagnosisCodeText
            self.checksum = checksum
            self.locale = locale
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toCappedClaimReservationView(_ item: CappedClaimReservation) -> CappedClaimReservationView {
        return CappedClaimReservationView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            currency: item.currency,
            payer: Kit.Text.truncate(item.payer, limit: 80),
            amount: String(format: "%.2f", item.amount),
            diagnosisCodeText: item.diagnosisCode,
            checksum: item.checksum,
            locale: item.locale,
            ceiling: String(format: "%.2f", item.ceiling),
            encounterID: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedClaimReservationViews(_ items: [CappedClaimReservation]) -> [CappedClaimReservationView] {
        var views: [CappedClaimReservationView] = []
        for item in items {
            views.append(toCappedClaimReservationView(item))
        }
        return views
    }

    static func sumCappedClaimReservationView(_ view: CappedClaimReservationView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedAmount + parsedCeiling
    }
}
