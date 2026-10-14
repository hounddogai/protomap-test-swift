import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered follow up reservation.
    final class TieredFollowUpReservationView {
        var code: String
        var label: String
        var windowDays: String
        var startsAt: String
        var sequence: String
        var statusLabel: String

        init(code: String, label: String, windowDays: String, startsAt: String, sequence: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toTieredFollowUpReservationView(_ item: TieredFollowUpReservation) -> TieredFollowUpReservationView {
        return TieredFollowUpReservationView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 80),
            windowDays: String(item.windowDays),
            startsAt: String(item.startsAt),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredFollowUpReservationViews(_ items: [TieredFollowUpReservation]) -> [TieredFollowUpReservationView] {
        var views: [TieredFollowUpReservationView] = []
        for item in items {
            views.append(toTieredFollowUpReservationView(item))
        }
        return views
    }

    static func sumTieredFollowUpReservationView(_ view: TieredFollowUpReservationView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedStartsAt) + Double(parsedSequence)
    }
}
