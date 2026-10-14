import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy reservation.
    final class ProxyReservationView {
        var codeText: String
        var name: String
        var weight: String
        var notes: String
        var cost: String
        var phoneText: String
        var floorValue: String
        var retriesText: String
        var statusLabel: String

        init(codeText: String, name: String, weight: String, notes: String, cost: String, phoneText: String, floorValue: String, retriesText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.weight = weight
            self.notes = notes
            self.cost = cost
            self.phoneText = phoneText
            self.floorValue = floorValue
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toProxyReservationView(_ item: ProxyReservation) -> ProxyReservationView {
        return ProxyReservationView(
            codeText: item.code,
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            notes: Kit.Text.truncate(item.notes, limit: 80),
            cost: String(format: "%.2f", item.cost),
            phoneText: item.phone,
            floorValue: String(format: "%.2f", item.floorValue),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyReservationViews(_ items: [ProxyReservation]) -> [ProxyReservationView] {
        var views: [ProxyReservationView] = []
        for item in items {
            views.append(toProxyReservationView(item))
        }
        return views
    }

    static func sumProxyReservationView(_ view: ProxyReservationView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedWeight + parsedCost + parsedFloorValue
    }
}
