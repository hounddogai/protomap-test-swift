import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure reservation.
    final class DisclosureReservationView {
        var code: String
        var title: String
        var updatedAt: String
        var source: String
        var versionText: String
        var statusLabel: String

        init(code: String, title: String, updatedAt: String, source: String, versionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.source = source
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureReservationView(_ item: DisclosureReservation) -> DisclosureReservationView {
        return DisclosureReservationView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            updatedAt: String(item.updatedAt),
            source: Kit.Text.truncate(item.source, limit: 80),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureReservationViews(_ items: [DisclosureReservation]) -> [DisclosureReservationView] {
        var views: [DisclosureReservationView] = []
        for item in items {
            views.append(toDisclosureReservationView(item))
        }
        return views
    }

    static func sumDisclosureReservationView(_ view: DisclosureReservationView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedVersion)
    }
}
