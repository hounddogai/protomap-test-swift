import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict skill mix audit.
    final class StrictSkillMixAuditView {
        var code: String
        var nameText: String
        var descriptionText: String
        var cost: String
        var weightText: String
        var reviewer: String
        var procedureCode: String
        var source: String
        var statusLabel: String

        init(code: String, nameText: String, descriptionText: String, cost: String, weightText: String, reviewer: String, procedureCode: String, source: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.descriptionText = descriptionText
            self.cost = cost
            self.weightText = weightText
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSkillMixAuditView(_ item: StrictSkillMixAudit) -> StrictSkillMixAuditView {
        return StrictSkillMixAuditView(
            code: item.code,
            nameText: item.name,
            descriptionText: Kit.Text.truncate(item.description, limit: 120),
            cost: String(format: "%.2f", item.cost),
            weightText: String(format: "%.2f", item.weight),
            reviewer: item.reviewer,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSkillMixAuditViews(_ items: [StrictSkillMixAudit]) -> [StrictSkillMixAuditView] {
        var views: [StrictSkillMixAuditView] = []
        for item in items {
            views.append(toStrictSkillMixAuditView(item))
        }
        return views
    }

    static func sumStrictSkillMixAuditView(_ view: StrictSkillMixAuditView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedCost + parsedWeight
    }
}
