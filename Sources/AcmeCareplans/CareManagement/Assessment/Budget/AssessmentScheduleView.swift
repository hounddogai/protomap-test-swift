import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment schedule.
    final class AssessmentScheduleView {
        var code: String
        var title: String
        var visible: String
        var notes: String
        var endsAt: String
        var active: String
        var externalRef: String
        var priorityText: String
        var acuityText: String
        var statusLabel: String

        init(code: String, title: String, visible: String, notes: String, endsAt: String, active: String, externalRef: String, priorityText: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visible = visible
            self.notes = notes
            self.endsAt = endsAt
            self.active = active
            self.externalRef = externalRef
            self.priorityText = priorityText
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentScheduleView(_ item: AssessmentSchedule) -> AssessmentScheduleView {
        return AssessmentScheduleView(
            code: item.code,
            title: item.title,
            visible: "\(item.visible)",
            notes: Kit.Text.truncate(item.notes, limit: 120),
            endsAt: String(item.endsAt),
            active: "\(item.active)",
            externalRef: item.externalRef,
            priorityText: String(item.priority),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentScheduleViews(_ items: [AssessmentSchedule]) -> [AssessmentScheduleView] {
        var views: [AssessmentScheduleView] = []
        for item in items {
            views.append(toAssessmentScheduleView(item))
        }
        return views
    }

    static func sumAssessmentScheduleView(_ view: AssessmentScheduleView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedPriority) + Double(parsedAcuity)
    }
}
