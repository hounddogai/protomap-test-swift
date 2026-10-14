import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read assignment.
    final class ReadAssignmentView {
        var code: String
        var name: String
        var patientRef: String
        var timezone: String
        var priority: String
        var approved: String
        var payer: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, patientRef: String, timezone: String, priority: String, approved: String, payer: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.timezone = timezone
            self.priority = priority
            self.approved = approved
            self.payer = payer
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toReadAssignmentView(_ item: ReadAssignment) -> ReadAssignmentView {
        return ReadAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 40),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            timezone: item.timezone,
            priority: String(item.priority),
            approved: "\(item.approved)",
            payer: item.payer,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadAssignmentViews(_ items: [ReadAssignment]) -> [ReadAssignmentView] {
        var views: [ReadAssignmentView] = []
        for item in items {
            views.append(toReadAssignmentView(item))
        }
        return views
    }

    static func sumReadAssignmentView(_ view: ReadAssignmentView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedPriority) + parsedBudget
    }
}
