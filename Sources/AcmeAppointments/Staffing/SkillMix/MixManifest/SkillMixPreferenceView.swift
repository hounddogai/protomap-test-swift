import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix preference.
    final class SkillMixPreferenceView {
        var codeText: String
        var label: String
        var cost: String
        var discount: String
        var margin: String
        var locale: String
        var unitText: String
        var active: String
        var statusLabel: String

        init(codeText: String, label: String, cost: String, discount: String, margin: String, locale: String, unitText: String, active: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.cost = cost
            self.discount = discount
            self.margin = margin
            self.locale = locale
            self.unitText = unitText
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixPreferenceView(_ item: SkillMixPreference) -> SkillMixPreferenceView {
        return SkillMixPreferenceView(
            codeText: item.code,
            label: item.label,
            cost: String(format: "%.2f", item.cost),
            discount: String(format: "%.2f", item.discount),
            margin: String(format: "%.2f", item.margin),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            unitText: item.unit,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixPreferenceViews(_ items: [SkillMixPreference]) -> [SkillMixPreferenceView] {
        var views: [SkillMixPreferenceView] = []
        for item in items {
            views.append(toSkillMixPreferenceView(item))
        }
        return views
    }

    static func sumSkillMixPreferenceView(_ view: SkillMixPreferenceView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedCost + parsedDiscount + parsedMargin
    }
}
