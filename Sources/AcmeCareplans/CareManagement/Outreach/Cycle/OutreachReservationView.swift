import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach reservation.
    final class OutreachReservationView {
        var codeText: String
        var label: String
        var notes: String
        var active: String
        var expiresAt: String
        var externalRef: String
        var payerText: String
        var reviewer: String
        var startsAt: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, notes: String, active: String, expiresAt: String, externalRef: String, payerText: String, reviewer: String, startsAt: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.notes = notes
            self.active = active
            self.expiresAt = expiresAt
            self.externalRef = externalRef
            self.payerText = payerText
            self.reviewer = reviewer
            self.startsAt = startsAt
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachReservationView(_ item: OutreachReservation) -> OutreachReservationView {
        return OutreachReservationView(
            codeText: item.code,
            label: item.label,
            notes: item.notes,
            active: "\(item.active)",
            expiresAt: String(item.expiresAt),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            payerText: item.payer,
            reviewer: item.reviewer,
            startsAt: String(item.startsAt),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachReservationViews(_ items: [OutreachReservation]) -> [OutreachReservationView] {
        var views: [OutreachReservationView] = []
        for item in items {
            views.append(toOutreachReservationView(item))
        }
        return views
    }

    static func sumOutreachReservationView(_ view: OutreachReservationView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedStartsAt) + Double(parsedVisitMinutes)
    }
}
