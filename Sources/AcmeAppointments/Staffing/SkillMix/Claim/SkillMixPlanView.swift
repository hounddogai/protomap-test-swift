import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix plan.
    final class SkillMixPlanView {
        var code: String
        var labelText: String
        var bedText: String
        var country: String
        var phoneText: String
        var contactEmail: String
        var timezone: String
        var localeText: String
        var archived: String
        var amount: String
        var statusLabel: String

        init(code: String, labelText: String, bedText: String, country: String, phoneText: String, contactEmail: String, timezone: String, localeText: String, archived: String, amount: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.bedText = bedText
            self.country = country
            self.phoneText = phoneText
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.localeText = localeText
            self.archived = archived
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixPlanView(_ item: SkillMixPlan) -> SkillMixPlanView {
        return SkillMixPlanView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            bedText: item.bed,
            country: item.country,
            phoneText: item.phone,
            contactEmail: item.contactEmail,
            timezone: item.timezone,
            localeText: item.locale,
            archived: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixPlanViews(_ items: [SkillMixPlan]) -> [SkillMixPlanView] {
        var views: [SkillMixPlanView] = []
        for item in items {
            views.append(toSkillMixPlanView(item))
        }
        return views
    }

    static func sumSkillMixPlanView(_ view: SkillMixPlanView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
