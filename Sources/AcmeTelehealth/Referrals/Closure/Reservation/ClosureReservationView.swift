import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure reservation.
    final class ClosureReservationView {
        var code: String
        var nameText: String
        var specialty: String
        var quantityText: String
        var descriptionText: String
        var revisionText: String
        var statusLabel: String

        init(code: String, nameText: String, specialty: String, quantityText: String, descriptionText: String, revisionText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.specialty = specialty
            self.quantityText = quantityText
            self.descriptionText = descriptionText
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureReservationView(_ item: ClosureReservation) -> ClosureReservationView {
        return ClosureReservationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            specialty: item.specialty,
            quantityText: String(item.quantity),
            descriptionText: item.description,
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureReservationViews(_ items: [ClosureReservation]) -> [ClosureReservationView] {
        var views: [ClosureReservationView] = []
        for item in items {
            views.append(toClosureReservationView(item))
        }
        return views
    }

    static func sumClosureReservationView(_ view: ClosureReservationView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedQuantity) + Double(parsedRevision)
    }
}
