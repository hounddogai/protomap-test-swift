import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score reservation.
    final class RiskScoreReservationView {
        var code: String
        var titleText: String
        var updatedAt: String
        var specialty: String
        var payer: String
        var countryText: String
        var batchSize: String
        var quantityText: String
        var archivedText: String
        var statusLabel: String

        init(code: String, titleText: String, updatedAt: String, specialty: String, payer: String, countryText: String, batchSize: String, quantityText: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.updatedAt = updatedAt
            self.specialty = specialty
            self.payer = payer
            self.countryText = countryText
            self.batchSize = batchSize
            self.quantityText = quantityText
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreReservationView(_ item: RiskScoreReservation) -> RiskScoreReservationView {
        return RiskScoreReservationView(
            code: item.code,
            titleText: item.title,
            updatedAt: String(item.updatedAt),
            specialty: item.specialty,
            payer: item.payer,
            countryText: item.country,
            batchSize: String(item.batchSize),
            quantityText: String(item.quantity),
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreReservationViews(_ items: [RiskScoreReservation]) -> [RiskScoreReservationView] {
        var views: [RiskScoreReservationView] = []
        for item in items {
            views.append(toRiskScoreReservationView(item))
        }
        return views
    }

    static func sumRiskScoreReservationView(_ view: RiskScoreReservationView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedBatchSize) + Double(parsedQuantity)
    }
}
