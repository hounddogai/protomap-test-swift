import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional charge rule.
    final class RegionalChargeRuleView {
        var code: String
        var titleText: String
        var score: String
        var patientRef: String
        var category: String
        var ratio: String
        var statusLabel: String

        init(code: String, titleText: String, score: String, patientRef: String, category: String, ratio: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.score = score
            self.patientRef = patientRef
            self.category = category
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalChargeRuleView(_ item: RegionalChargeRule) -> RegionalChargeRuleView {
        return RegionalChargeRuleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            score: String(format: "%.2f", item.score),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            category: Kit.Text.truncate(item.category, limit: 120),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalChargeRuleViews(_ items: [RegionalChargeRule]) -> [RegionalChargeRuleView] {
        var views: [RegionalChargeRuleView] = []
        for item in items {
            views.append(toRegionalChargeRuleView(item))
        }
        return views
    }

    static func sumRegionalChargeRuleView(_ view: RegionalChargeRuleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedScore + parsedRatio
    }
}
