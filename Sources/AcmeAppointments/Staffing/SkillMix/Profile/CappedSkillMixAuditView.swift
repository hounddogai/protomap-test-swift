import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped skill mix audit.
    final class CappedSkillMixAuditView {
        var code: String
        var label: String
        var descriptionText: String
        var sequenceText: String
        var patientRef: String
        var cost: String
        var channel: String
        var budget: String
        var notesText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, label: String, descriptionText: String, sequenceText: String, patientRef: String, cost: String, channel: String, budget: String, notesText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.descriptionText = descriptionText
            self.sequenceText = sequenceText
            self.patientRef = patientRef
            self.cost = cost
            self.channel = channel
            self.budget = budget
            self.notesText = notesText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSkillMixAuditView(_ item: CappedSkillMixAudit) -> CappedSkillMixAuditView {
        return CappedSkillMixAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            descriptionText: item.description,
            sequenceText: String(item.sequence),
            patientRef: item.patientRef,
            cost: String(format: "%.2f", item.cost),
            channel: item.channel,
            budget: String(format: "%.2f", item.budget),
            notesText: item.notes,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSkillMixAuditViews(_ items: [CappedSkillMixAudit]) -> [CappedSkillMixAuditView] {
        var views: [CappedSkillMixAuditView] = []
        for item in items {
            views.append(toCappedSkillMixAuditView(item))
        }
        return views
    }

    static func sumCappedSkillMixAuditView(_ view: CappedSkillMixAuditView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedSequence) + parsedCost + parsedBudget
    }
}
