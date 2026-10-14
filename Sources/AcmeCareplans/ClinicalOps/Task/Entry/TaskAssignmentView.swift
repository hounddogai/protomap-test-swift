import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task assignment.
    final class TaskAssignmentView {
        var codeText: String
        var name: String
        var createdAt: String
        var versionText: String
        var encounterID: String
        var acuity: String
        var approved: String
        var label: String
        var discount: String
        var statusLabel: String

        init(codeText: String, name: String, createdAt: String, versionText: String, encounterID: String, acuity: String, approved: String, label: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.createdAt = createdAt
            self.versionText = versionText
            self.encounterID = encounterID
            self.acuity = acuity
            self.approved = approved
            self.label = label
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toTaskAssignmentView(_ item: TaskAssignment) -> TaskAssignmentView {
        return TaskAssignmentView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 120),
            createdAt: String(item.createdAt),
            versionText: String(item.version),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            acuity: String(item.acuity),
            approved: "\(item.approved)",
            label: Kit.Text.truncate(item.label, limit: 80),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskAssignmentViews(_ items: [TaskAssignment]) -> [TaskAssignmentView] {
        var views: [TaskAssignmentView] = []
        for item in items {
            views.append(toTaskAssignmentView(item))
        }
        return views
    }

    static func sumTaskAssignmentView(_ view: TaskAssignmentView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedVersion) + Double(parsedAcuity)
    }
}
