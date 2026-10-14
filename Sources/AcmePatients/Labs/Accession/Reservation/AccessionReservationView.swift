import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession reservation.
    final class AccessionReservationView {
        var code: String
        var label: String
        var expiresAt: String
        var capacityText: String
        var priority: String
        var attempts: String
        var pinned: String
        var visibleText: String
        var minimumText: String
        var quantityText: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, label: String, expiresAt: String, capacityText: String, priority: String, attempts: String, pinned: String, visibleText: String, minimumText: String, quantityText: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.capacityText = capacityText
            self.priority = priority
            self.attempts = attempts
            self.pinned = pinned
            self.visibleText = visibleText
            self.minimumText = minimumText
            self.quantityText = quantityText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionReservationView(_ item: AccessionReservation) -> AccessionReservationView {
        return AccessionReservationView(
            code: item.code,
            label: item.label,
            expiresAt: String(item.expiresAt),
            capacityText: String(item.capacity),
            priority: String(item.priority),
            attempts: String(item.attempts),
            pinned: "\(item.pinned)",
            visibleText: "\(item.visible)",
            minimumText: String(format: "%.2f", item.minimum),
            quantityText: String(item.quantity),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionReservationViews(_ items: [AccessionReservation]) -> [AccessionReservationView] {
        var views: [AccessionReservationView] = []
        for item in items {
            views.append(toAccessionReservationView(item))
        }
        return views
    }

    static func sumAccessionReservationView(_ view: AccessionReservationView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedCapacity) + Double(parsedPriority)
    }
}
