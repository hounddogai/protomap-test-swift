import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive care protocol reservation.
    final class AdaptiveCareProtocolReservationView {
        var codeText: String
        var name: String
        var visitMinutes: String
        var archivedText: String
        var sequence: String
        var startsAt: String
        var clinicianID: String
        var visible: String
        var statusLabel: String

        init(codeText: String, name: String, visitMinutes: String, archivedText: String, sequence: String, startsAt: String, clinicianID: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.visitMinutes = visitMinutes
            self.archivedText = archivedText
            self.sequence = sequence
            self.startsAt = startsAt
            self.clinicianID = clinicianID
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCareProtocolReservationView(_ item: AdaptiveCareProtocolReservation) -> AdaptiveCareProtocolReservationView {
        return AdaptiveCareProtocolReservationView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            visitMinutes: String(item.visitMinutes),
            archivedText: "\(item.archived)",
            sequence: String(item.sequence),
            startsAt: String(item.startsAt),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCareProtocolReservationViews(_ items: [AdaptiveCareProtocolReservation]) -> [AdaptiveCareProtocolReservationView] {
        var views: [AdaptiveCareProtocolReservationView] = []
        for item in items {
            views.append(toAdaptiveCareProtocolReservationView(item))
        }
        return views
    }

    static func sumAdaptiveCareProtocolReservationView(_ view: AdaptiveCareProtocolReservationView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedSequence) + Double(parsedStartsAt)
    }
}
