import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling outreach reservation.
    final class RollingOutreachReservationView {
        var code: String
        var label: String
        var graceDays: String
        var retries: String
        var updatedAt: String
        var endsAtText: String
        var limit: String
        var discount: String
        var statusLabel: String

        init(code: String, label: String, graceDays: String, retries: String, updatedAt: String, endsAtText: String, limit: String, discount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.retries = retries
            self.updatedAt = updatedAt
            self.endsAtText = endsAtText
            self.limit = limit
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toRollingOutreachReservationView(_ item: RollingOutreachReservation) -> RollingOutreachReservationView {
        return RollingOutreachReservationView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            graceDays: String(item.graceDays),
            retries: String(item.retries),
            updatedAt: String(item.updatedAt),
            endsAtText: String(item.endsAt),
            limit: String(item.limit),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingOutreachReservationViews(_ items: [RollingOutreachReservation]) -> [RollingOutreachReservationView] {
        var views: [RollingOutreachReservationView] = []
        for item in items {
            views.append(toRollingOutreachReservationView(item))
        }
        return views
    }

    static func sumRollingOutreachReservationView(_ view: RollingOutreachReservationView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRetries) + Double(parsedUpdatedAt)
    }
}
