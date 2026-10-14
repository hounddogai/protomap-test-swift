import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict skill mix override.
    final class StrictSkillMixOverrideView {
        var code: String
        var nameText: String
        var contactEmailText: String
        var visitMinutes: String
        var budget: String
        var description: String
        var thresholdText: String
        var batchSize: String
        var priority: String
        var notes: String
        var archived: String
        var statusLabel: String

        init(code: String, nameText: String, contactEmailText: String, visitMinutes: String, budget: String, description: String, thresholdText: String, batchSize: String, priority: String, notes: String, archived: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.contactEmailText = contactEmailText
            self.visitMinutes = visitMinutes
            self.budget = budget
            self.description = description
            self.thresholdText = thresholdText
            self.batchSize = batchSize
            self.priority = priority
            self.notes = notes
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSkillMixOverrideView(_ item: StrictSkillMixOverride) -> StrictSkillMixOverrideView {
        return StrictSkillMixOverrideView(
            code: item.code,
            nameText: item.name,
            contactEmailText: item.contactEmail,
            visitMinutes: String(item.visitMinutes),
            budget: String(format: "%.2f", item.budget),
            description: Kit.Text.truncate(item.description, limit: 120),
            thresholdText: String(format: "%.2f", item.threshold),
            batchSize: String(item.batchSize),
            priority: String(item.priority),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSkillMixOverrideViews(_ items: [StrictSkillMixOverride]) -> [StrictSkillMixOverrideView] {
        var views: [StrictSkillMixOverrideView] = []
        for item in items {
            views.append(toStrictSkillMixOverrideView(item))
        }
        return views
    }

    static func sumStrictSkillMixOverrideView(_ view: StrictSkillMixOverrideView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedVisitMinutes) + parsedBudget + parsedThreshold
    }
}
