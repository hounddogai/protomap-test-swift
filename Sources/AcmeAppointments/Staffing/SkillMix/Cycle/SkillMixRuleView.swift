import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix rule.
    final class SkillMixRuleView {
        var code: String
        var name: String
        var region: String
        var ownerIDText: String
        var segment: String
        var amount: String
        var statusLabel: String

        init(code: String, name: String, region: String, ownerIDText: String, segment: String, amount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.region = region
            self.ownerIDText = ownerIDText
            self.segment = segment
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixRuleView(_ item: SkillMixRule) -> SkillMixRuleView {
        return SkillMixRuleView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            region: item.region,
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 40),
            segment: item.segment,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixRuleViews(_ items: [SkillMixRule]) -> [SkillMixRuleView] {
        var views: [SkillMixRuleView] = []
        for item in items {
            views.append(toSkillMixRuleView(item))
        }
        return views
    }

    static func sumSkillMixRuleView(_ view: SkillMixRuleView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
