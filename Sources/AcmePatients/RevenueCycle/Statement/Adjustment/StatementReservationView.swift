import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement reservation.
    final class StatementReservationView {
        var code: String
        var title: String
        var ward: String
        var clinicianID: String
        var pinnedText: String
        var graceDays: String
        var archived: String
        var checksum: String
        var statusLabel: String

        init(code: String, title: String, ward: String, clinicianID: String, pinnedText: String, graceDays: String, archived: String, checksum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ward = ward
            self.clinicianID = clinicianID
            self.pinnedText = pinnedText
            self.graceDays = graceDays
            self.archived = archived
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toStatementReservationView(_ item: StatementReservation) -> StatementReservationView {
        return StatementReservationView(
            code: item.code,
            title: item.title,
            ward: Kit.Text.truncate(item.ward, limit: 64),
            clinicianID: item.clinicianID,
            pinnedText: "\(item.pinned)",
            graceDays: String(item.graceDays),
            archived: "\(item.archived)",
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementReservationViews(_ items: [StatementReservation]) -> [StatementReservationView] {
        var views: [StatementReservationView] = []
        for item in items {
            views.append(toStatementReservationView(item))
        }
        return views
    }

    static func sumStatementReservationView(_ view: StatementReservationView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
