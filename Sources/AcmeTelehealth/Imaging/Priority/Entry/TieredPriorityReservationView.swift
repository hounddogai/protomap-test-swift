import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered priority reservation.
    final class TieredPriorityReservationView {
        var code: String
        var title: String
        var priority: String
        var retries: String
        var encounterID: String
        var timezone: String
        var payer: String
        var statusLabel: String

        init(code: String, title: String, priority: String, retries: String, encounterID: String, timezone: String, payer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.priority = priority
            self.retries = retries
            self.encounterID = encounterID
            self.timezone = timezone
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toTieredPriorityReservationView(_ item: TieredPriorityReservation) -> TieredPriorityReservationView {
        return TieredPriorityReservationView(
            code: item.code,
            title: item.title,
            priority: String(item.priority),
            retries: String(item.retries),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredPriorityReservationViews(_ items: [TieredPriorityReservation]) -> [TieredPriorityReservationView] {
        var views: [TieredPriorityReservationView] = []
        for item in items {
            views.append(toTieredPriorityReservationView(item))
        }
        return views
    }

    static func sumTieredPriorityReservationView(_ view: TieredPriorityReservationView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedPriority) + Double(parsedRetries)
    }
}
