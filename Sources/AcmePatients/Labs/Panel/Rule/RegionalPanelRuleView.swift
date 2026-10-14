import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional panel rule.
    final class RegionalPanelRuleView {
        var code: String
        var title: String
        var ceiling: String
        var diagnosisCode: String
        var minimumText: String
        var facility: String
        var limit: String
        var archived: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, diagnosisCode: String, minimumText: String, facility: String, limit: String, archived: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.diagnosisCode = diagnosisCode
            self.minimumText = minimumText
            self.facility = facility
            self.limit = limit
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalPanelRuleView(_ item: RegionalPanelRule) -> RegionalPanelRuleView {
        return RegionalPanelRuleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            diagnosisCode: item.diagnosisCode,
            minimumText: String(format: "%.2f", item.minimum),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            limit: String(item.limit),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalPanelRuleViews(_ items: [RegionalPanelRule]) -> [RegionalPanelRuleView] {
        var views: [RegionalPanelRuleView] = []
        for item in items {
            views.append(toRegionalPanelRuleView(item))
        }
        return views
    }

    static func sumRegionalPanelRuleView(_ view: RegionalPanelRuleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedCeiling + parsedMinimum + Double(parsedLimit)
    }
}
