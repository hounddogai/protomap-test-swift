import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task plan.
    final class TaskPlanView {
        var code: String
        var labelText: String
        var approved: String
        var priority: String
        var durationMinutes: String
        var sequence: String
        var retries: String
        var statusLabel: String

        init(code: String, labelText: String, approved: String, priority: String, durationMinutes: String, sequence: String, retries: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.approved = approved
            self.priority = priority
            self.durationMinutes = durationMinutes
            self.sequence = sequence
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toTaskPlanView(_ item: TaskPlan) -> TaskPlanView {
        return TaskPlanView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            approved: "\(item.approved)",
            priority: String(item.priority),
            durationMinutes: String(item.durationMinutes),
            sequence: String(item.sequence),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskPlanViews(_ items: [TaskPlan]) -> [TaskPlanView] {
        var views: [TaskPlanView] = []
        for item in items {
            views.append(toTaskPlanView(item))
        }
        return views
    }

    static func sumTaskPlanView(_ view: TaskPlanView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedPriority) + Double(parsedDurationMinutes) + Double(parsedSequence)
    }
}
