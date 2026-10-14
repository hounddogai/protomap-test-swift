import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional disclosure reservation.
    final class RegionalDisclosureReservationView {
        var code: String
        var title: String
        var copay: String
        var facility: String
        var currency: String
        var refillsText: String
        var minimum: String
        var ownerID: String
        var weight: String
        var statusLabel: String

        init(code: String, title: String, copay: String, facility: String, currency: String, refillsText: String, minimum: String, ownerID: String, weight: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.copay = copay
            self.facility = facility
            self.currency = currency
            self.refillsText = refillsText
            self.minimum = minimum
            self.ownerID = ownerID
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalDisclosureReservationView(_ item: RegionalDisclosureReservation) -> RegionalDisclosureReservationView {
        return RegionalDisclosureReservationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            copay: String(format: "%.2f", item.copay),
            facility: item.facility,
            currency: item.currency,
            refillsText: String(item.refills),
            minimum: String(format: "%.2f", item.minimum),
            ownerID: item.ownerID,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalDisclosureReservationViews(_ items: [RegionalDisclosureReservation]) -> [RegionalDisclosureReservationView] {
        var views: [RegionalDisclosureReservationView] = []
        for item in items {
            views.append(toRegionalDisclosureReservationView(item))
        }
        return views
    }

    static func sumRegionalDisclosureReservationView(_ view: RegionalDisclosureReservationView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedCopay + Double(parsedRefills) + parsedMinimum
    }
}
