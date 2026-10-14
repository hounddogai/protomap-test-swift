import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending goal schedule.
    final class PendingGoalScheduleView {
        var codeText: String
        var name: String
        var weightText: String
        var bed: String
        var approved: String
        var expiresAt: String
        var reviewer: String
        var revisionText: String
        var capacity: String
        var specialty: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, name: String, weightText: String, bed: String, approved: String, expiresAt: String, reviewer: String, revisionText: String, capacity: String, specialty: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.weightText = weightText
            self.bed = bed
            self.approved = approved
            self.expiresAt = expiresAt
            self.reviewer = reviewer
            self.revisionText = revisionText
            self.capacity = capacity
            self.specialty = specialty
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPendingGoalScheduleView(_ item: PendingGoalSchedule) -> PendingGoalScheduleView {
        return PendingGoalScheduleView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            weightText: String(format: "%.2f", item.weight),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            approved: "\(item.approved)",
            expiresAt: String(item.expiresAt),
            reviewer: item.reviewer,
            revisionText: String(item.revision),
            capacity: String(item.capacity),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingGoalScheduleViews(_ items: [PendingGoalSchedule]) -> [PendingGoalScheduleView] {
        var views: [PendingGoalScheduleView] = []
        for item in items {
            views.append(toPendingGoalScheduleView(item))
        }
        return views
    }

    static func sumPendingGoalScheduleView(_ view: PendingGoalScheduleView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedWeight + Double(parsedExpiresAt) + Double(parsedRevision)
    }
}
