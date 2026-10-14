import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix window.
    final class SkillMixWindowView {
        var codeText: String
        var title: String
        var clinicianID: String
        var maximum: String
        var source: String
        var costText: String
        var acuity: String
        var statusLabel: String

        init(codeText: String, title: String, clinicianID: String, maximum: String, source: String, costText: String, acuity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.clinicianID = clinicianID
            self.maximum = maximum
            self.source = source
            self.costText = costText
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixWindowView(_ item: SkillMixWindow) -> SkillMixWindowView {
        return SkillMixWindowView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            clinicianID: item.clinicianID,
            maximum: String(format: "%.2f", item.maximum),
            source: item.source,
            costText: String(format: "%.2f", item.cost),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixWindowViews(_ items: [SkillMixWindow]) -> [SkillMixWindowView] {
        var views: [SkillMixWindowView] = []
        for item in items {
            views.append(toSkillMixWindowView(item))
        }
        return views
    }

    static func sumSkillMixWindowView(_ view: SkillMixWindowView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedMaximum + parsedCost + Double(parsedAcuity)
    }
}
