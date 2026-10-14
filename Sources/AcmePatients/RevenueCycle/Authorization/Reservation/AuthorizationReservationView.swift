import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization reservation.
    final class AuthorizationReservationView {
        var code: String
        var titleText: String
        var graceDaysText: String
        var allergy: String
        var expiresAtText: String
        var version: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, titleText: String, graceDaysText: String, allergy: String, expiresAtText: String, version: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.graceDaysText = graceDaysText
            self.allergy = allergy
            self.expiresAtText = expiresAtText
            self.version = version
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationReservationView(_ item: AuthorizationReservation) -> AuthorizationReservationView {
        return AuthorizationReservationView(
            code: item.code,
            titleText: item.title,
            graceDaysText: String(item.graceDays),
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            expiresAtText: String(item.expiresAt),
            version: String(item.version),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationReservationViews(_ items: [AuthorizationReservation]) -> [AuthorizationReservationView] {
        var views: [AuthorizationReservationView] = []
        for item in items {
            views.append(toAuthorizationReservationView(item))
        }
        return views
    }

    static func sumAuthorizationReservationView(_ view: AuthorizationReservationView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedExpiresAt) + Double(parsedVersion)
    }
}
