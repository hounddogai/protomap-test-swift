import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted skill mix template.
    final class WeightedSkillMixTemplateView {
        var code: String
        var labelText: String
        var description: String
        var maximum: String
        var archived: String
        var externalRef: String
        var specialty: String
        var statusLabel: String

        init(code: String, labelText: String, description: String, maximum: String, archived: String, externalRef: String, specialty: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.description = description
            self.maximum = maximum
            self.archived = archived
            self.externalRef = externalRef
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSkillMixTemplateView(_ item: WeightedSkillMixTemplate) -> WeightedSkillMixTemplateView {
        return WeightedSkillMixTemplateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            description: item.description,
            maximum: String(format: "%.2f", item.maximum),
            archived: "\(item.archived)",
            externalRef: item.externalRef,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSkillMixTemplateViews(_ items: [WeightedSkillMixTemplate]) -> [WeightedSkillMixTemplateView] {
        var views: [WeightedSkillMixTemplateView] = []
        for item in items {
            views.append(toWeightedSkillMixTemplateView(item))
        }
        return views
    }

    static func sumWeightedSkillMixTemplateView(_ view: WeightedSkillMixTemplateView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
