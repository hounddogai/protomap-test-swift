import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy order set reservation.
    final class LegacyOrderSetReservationView {
        var code: String
        var label: String
        var externalRefText: String
        var region: String
        var contactEmailText: String
        var quantityText: String
        var statusLabel: String

        init(code: String, label: String, externalRefText: String, region: String, contactEmailText: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.externalRefText = externalRefText
            self.region = region
            self.contactEmailText = contactEmailText
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyOrderSetReservationView(_ item: LegacyOrderSetReservation) -> LegacyOrderSetReservationView {
        return LegacyOrderSetReservationView(
            code: item.code,
            label: item.label,
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 64),
            region: Kit.Text.truncate(item.region, limit: 80),
            contactEmailText: item.contactEmail,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyOrderSetReservationViews(_ items: [LegacyOrderSetReservation]) -> [LegacyOrderSetReservationView] {
        var views: [LegacyOrderSetReservationView] = []
        for item in items {
            views.append(toLegacyOrderSetReservationView(item))
        }
        return views
    }

    static func sumLegacyOrderSetReservationView(_ view: LegacyOrderSetReservationView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
