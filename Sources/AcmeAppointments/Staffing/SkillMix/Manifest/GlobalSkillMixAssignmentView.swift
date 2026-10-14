import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global skill mix assignment.
    final class GlobalSkillMixAssignmentView {
        var code: String
        var title: String
        var visitMinutes: String
        var archived: String
        var unit: String
        var score: String
        var currency: String
        var thresholdText: String
        var statusLabel: String

        init(code: String, title: String, visitMinutes: String, archived: String, unit: String, score: String, currency: String, thresholdText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.archived = archived
            self.unit = unit
            self.score = score
            self.currency = currency
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSkillMixAssignmentView(_ item: GlobalSkillMixAssignment) -> GlobalSkillMixAssignmentView {
        return GlobalSkillMixAssignmentView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            visitMinutes: String(item.visitMinutes),
            archived: "\(item.archived)",
            unit: item.unit,
            score: String(format: "%.2f", item.score),
            currency: Kit.Text.truncate(item.currency, limit: 64),
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSkillMixAssignmentViews(_ items: [GlobalSkillMixAssignment]) -> [GlobalSkillMixAssignmentView] {
        var views: [GlobalSkillMixAssignmentView] = []
        for item in items {
            views.append(toGlobalSkillMixAssignmentView(item))
        }
        return views
    }

    static func sumGlobalSkillMixAssignmentView(_ view: GlobalSkillMixAssignmentView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedVisitMinutes) + parsedScore + parsedThreshold
    }
}
