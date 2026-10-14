import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot reservation.
    final class SlotReservationView {
        var codeText: String
        var title: String
        var categoryText: String
        var name: String
        var windowDays: String
        var minimum: String
        var active: String
        var cost: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, title: String, categoryText: String, name: String, windowDays: String, minimum: String, active: String, cost: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.categoryText = categoryText
            self.name = name
            self.windowDays = windowDays
            self.minimum = minimum
            self.active = active
            self.cost = cost
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toSlotReservationView(_ item: SlotReservation) -> SlotReservationView {
        return SlotReservationView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            categoryText: item.category,
            name: item.name,
            windowDays: String(item.windowDays),
            minimum: String(format: "%.2f", item.minimum),
            active: "\(item.active)",
            cost: String(format: "%.2f", item.cost),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotReservationViews(_ items: [SlotReservation]) -> [SlotReservationView] {
        var views: [SlotReservationView] = []
        for item in items {
            views.append(toSlotReservationView(item))
        }
        return views
    }

    static func sumSlotReservationView(_ view: SlotReservationView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedWindowDays) + parsedMinimum + parsedCost
    }
}
