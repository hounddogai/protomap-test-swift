import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending claim reservation.
    final class PendingClaimReservationView {
        var code: String
        var name: String
        var graceDays: String
        var timezone: String
        var copay: String
        var contactEmailText: String
        var retries: String
        var statusLabel: String

        init(code: String, name: String, graceDays: String, timezone: String, copay: String, contactEmailText: String, retries: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.timezone = timezone
            self.copay = copay
            self.contactEmailText = contactEmailText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toPendingClaimReservationView(_ item: PendingClaimReservation) -> PendingClaimReservationView {
        return PendingClaimReservationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            graceDays: String(item.graceDays),
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            copay: String(format: "%.2f", item.copay),
            contactEmailText: item.contactEmail,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingClaimReservationViews(_ items: [PendingClaimReservation]) -> [PendingClaimReservationView] {
        var views: [PendingClaimReservationView] = []
        for item in items {
            views.append(toPendingClaimReservationView(item))
        }
        return views
    }

    static func sumPendingClaimReservationView(_ view: PendingClaimReservationView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedGraceDays) + parsedCopay + Double(parsedRetries)
    }
}
