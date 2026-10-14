import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a rolling float pool score.
    final class RollingFloatPoolScoreView {
        var codeText: String
        var label: String
        var budgetText: String
        var bed: String
        var limit: String
        var encounterIDText: String
        var locale: String
        var visitMinutes: String
        var retriesText: String
        var thresholdText: String
        var statusLabel: String

        init(codeText: String, label: String, budgetText: String, bed: String, limit: String, encounterIDText: String, locale: String, visitMinutes: String, retriesText: String, thresholdText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.budgetText = budgetText
            self.bed = bed
            self.limit = limit
            self.encounterIDText = encounterIDText
            self.locale = locale
            self.visitMinutes = visitMinutes
            self.retriesText = retriesText
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingFloatPoolScoreView(_ item: RollingFloatPoolScore) -> RollingFloatPoolScoreView {
        return RollingFloatPoolScoreView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            budgetText: String(format: "%.2f", item.budget),
            bed: Kit.Text.truncate(item.bed, limit: 120),
            limit: String(item.limit),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 64),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            visitMinutes: String(item.visitMinutes),
            retriesText: String(item.retries),
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingFloatPoolScoreViews(_ items: [RollingFloatPoolScore]) -> [RollingFloatPoolScoreView] {
        var views: [RollingFloatPoolScoreView] = []
        for item in items {
            views.append(toRollingFloatPoolScoreView(item))
        }
        return views
    }

    static func sumRollingFloatPoolScoreView(_ view: RollingFloatPoolScoreView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedBudget + Double(parsedLimit) + Double(parsedVisitMinutes)
    }
}
