import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict handoff reservation.
    final class StrictHandoffReservationView {
        var code: String
        var label: String
        var name: String
        var country: String
        var notes: String
        var capacityText: String
        var statusLabel: String

        init(code: String, label: String, name: String, country: String, notes: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.country = country
            self.notes = notes
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictHandoffReservationView(_ item: StrictHandoffReservation) -> StrictHandoffReservationView {
        return StrictHandoffReservationView(
            code: item.code,
            label: item.label,
            name: item.name,
            country: Kit.Text.truncate(item.country, limit: 80),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictHandoffReservationViews(_ items: [StrictHandoffReservation]) -> [StrictHandoffReservationView] {
        var views: [StrictHandoffReservationView] = []
        for item in items {
            views.append(toStrictHandoffReservationView(item))
        }
        return views
    }

    static func sumStrictHandoffReservationView(_ view: StrictHandoffReservationView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedCapacity)
    }
}
