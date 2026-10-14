import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending shift reservation.
    final class PendingShiftReservationView {
        var code: String
        var label: String
        var visible: String
        var notesText: String
        var contactEmailText: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, visible: String, notesText: String, contactEmailText: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visible = visible
            self.notesText = notesText
            self.contactEmailText = contactEmailText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toPendingShiftReservationView(_ item: PendingShiftReservation) -> PendingShiftReservationView {
        return PendingShiftReservationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 64),
            visible: "\(item.visible)",
            notesText: item.notes,
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 64),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingShiftReservationViews(_ items: [PendingShiftReservation]) -> [PendingShiftReservationView] {
        var views: [PendingShiftReservationView] = []
        for item in items {
            views.append(toPendingShiftReservationView(item))
        }
        return views
    }

    static func sumPendingShiftReservationView(_ view: PendingShiftReservationView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
