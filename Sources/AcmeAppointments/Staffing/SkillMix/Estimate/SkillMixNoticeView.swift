import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix notice.
    final class SkillMixNoticeView {
        var code: String
        var name: String
        var minimum: String
        var timezone: String
        var acuity: String
        var category: String
        var batchSize: String
        var budget: String
        var bedText: String
        var statusLabel: String

        init(code: String, name: String, minimum: String, timezone: String, acuity: String, category: String, batchSize: String, budget: String, bedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.timezone = timezone
            self.acuity = acuity
            self.category = category
            self.batchSize = batchSize
            self.budget = budget
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixNoticeView(_ item: SkillMixNotice) -> SkillMixNoticeView {
        return SkillMixNoticeView(
            code: item.code,
            name: item.name,
            minimum: String(format: "%.2f", item.minimum),
            timezone: item.timezone,
            acuity: String(item.acuity),
            category: item.category,
            batchSize: String(item.batchSize),
            budget: String(format: "%.2f", item.budget),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixNoticeViews(_ items: [SkillMixNotice]) -> [SkillMixNoticeView] {
        var views: [SkillMixNoticeView] = []
        for item in items {
            views.append(toSkillMixNoticeView(item))
        }
        return views
    }

    static func sumSkillMixNoticeView(_ view: SkillMixNoticeView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedMinimum + Double(parsedAcuity) + Double(parsedBatchSize)
    }
}
