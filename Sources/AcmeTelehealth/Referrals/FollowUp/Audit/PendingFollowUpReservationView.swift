import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending follow up reservation.
    final class PendingFollowUpReservationView {
        var code: String
        var label: String
        var ownerID: String
        var approvedText: String
        var revision: String
        var createdAtText: String
        var facility: String
        var archivedText: String
        var weightText: String
        var statusLabel: String

        init(code: String, label: String, ownerID: String, approvedText: String, revision: String, createdAtText: String, facility: String, archivedText: String, weightText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.approvedText = approvedText
            self.revision = revision
            self.createdAtText = createdAtText
            self.facility = facility
            self.archivedText = archivedText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingFollowUpReservationView(_ item: PendingFollowUpReservation) -> PendingFollowUpReservationView {
        return PendingFollowUpReservationView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            ownerID: item.ownerID,
            approvedText: "\(item.approved)",
            revision: String(item.revision),
            createdAtText: String(item.createdAt),
            facility: item.facility,
            archivedText: "\(item.archived)",
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingFollowUpReservationViews(_ items: [PendingFollowUpReservation]) -> [PendingFollowUpReservationView] {
        var views: [PendingFollowUpReservationView] = []
        for item in items {
            views.append(toPendingFollowUpReservationView(item))
        }
        return views
    }

    static func sumPendingFollowUpReservationView(_ view: PendingFollowUpReservationView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedRevision) + Double(parsedCreatedAt) + parsedWeight
    }
}
