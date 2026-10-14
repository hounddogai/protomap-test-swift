import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global skill mix record.
    final class GlobalSkillMixRecordView {
        var code: String
        var label: String
        var updatedAt: String
        var score: String
        var minimum: String
        var quantityText: String
        var budgetText: String
        var sourceText: String
        var name: String
        var contactEmailText: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, updatedAt: String, score: String, minimum: String, quantityText: String, budgetText: String, sourceText: String, name: String, contactEmailText: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.score = score
            self.minimum = minimum
            self.quantityText = quantityText
            self.budgetText = budgetText
            self.sourceText = sourceText
            self.name = name
            self.contactEmailText = contactEmailText
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSkillMixRecordView(_ item: GlobalSkillMixRecord) -> GlobalSkillMixRecordView {
        return GlobalSkillMixRecordView(
            code: item.code,
            label: item.label,
            updatedAt: String(item.updatedAt),
            score: String(format: "%.2f", item.score),
            minimum: String(format: "%.2f", item.minimum),
            quantityText: String(item.quantity),
            budgetText: String(format: "%.2f", item.budget),
            sourceText: Kit.Text.truncate(item.source, limit: 120),
            name: item.name,
            contactEmailText: item.contactEmail,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSkillMixRecordViews(_ items: [GlobalSkillMixRecord]) -> [GlobalSkillMixRecordView] {
        var views: [GlobalSkillMixRecordView] = []
        for item in items {
            views.append(toGlobalSkillMixRecordView(item))
        }
        return views
    }

    static func sumGlobalSkillMixRecordView(_ view: GlobalSkillMixRecordView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedUpdatedAt) + parsedScore + parsedMinimum
    }
}
