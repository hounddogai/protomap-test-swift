import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending cleaning reservation.
    final class PendingCleaningReservationView {
        var codeText: String
        var title: String
        var approved: String
        var segmentText: String
        var thresholdText: String
        var ownerIDText: String
        var externalRefText: String
        var specialty: String
        var clinicianID: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, title: String, approved: String, segmentText: String, thresholdText: String, ownerIDText: String, externalRefText: String, specialty: String, clinicianID: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.approved = approved
            self.segmentText = segmentText
            self.thresholdText = thresholdText
            self.ownerIDText = ownerIDText
            self.externalRefText = externalRefText
            self.specialty = specialty
            self.clinicianID = clinicianID
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCleaningReservationView(_ item: PendingCleaningReservation) -> PendingCleaningReservationView {
        return PendingCleaningReservationView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            approved: "\(item.approved)",
            segmentText: item.segment,
            thresholdText: String(format: "%.2f", item.threshold),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 64),
            externalRefText: item.externalRef,
            specialty: item.specialty,
            clinicianID: item.clinicianID,
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCleaningReservationViews(_ items: [PendingCleaningReservation]) -> [PendingCleaningReservationView] {
        var views: [PendingCleaningReservationView] = []
        for item in items {
            views.append(toPendingCleaningReservationView(item))
        }
        return views
    }

    static func sumPendingCleaningReservationView(_ view: PendingCleaningReservationView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedThreshold + Double(parsedCapacity)
    }
}
