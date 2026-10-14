import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix template.
    final class SkillMixTemplateView {
        var code: String
        var label: String
        var channelText: String
        var unitText: String
        var margin: String
        var timezone: String
        var floorValue: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, label: String, channelText: String, unitText: String, margin: String, timezone: String, floorValue: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channelText = channelText
            self.unitText = unitText
            self.margin = margin
            self.timezone = timezone
            self.floorValue = floorValue
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixTemplateView(_ item: SkillMixTemplate) -> SkillMixTemplateView {
        return SkillMixTemplateView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            channelText: Kit.Text.truncate(item.channel, limit: 120),
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            margin: String(format: "%.2f", item.margin),
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixTemplateViews(_ items: [SkillMixTemplate]) -> [SkillMixTemplateView] {
        var views: [SkillMixTemplateView] = []
        for item in items {
            views.append(toSkillMixTemplateView(item))
        }
        return views
    }

    static func sumSkillMixTemplateView(_ view: SkillMixTemplateView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedMargin + parsedFloorValue
    }
}
