import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling care protocol rule.
    final class RollingCareProtocolRuleView {
        var code: String
        var titleText: String
        var visitMinutesText: String
        var scoreText: String
        var currency: String
        var name: String
        var region: String
        var priorityText: String
        var ownerID: String
        var windowDays: String
        var payerText: String
        var statusLabel: String

        init(code: String, titleText: String, visitMinutesText: String, scoreText: String, currency: String, name: String, region: String, priorityText: String, ownerID: String, windowDays: String, payerText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.visitMinutesText = visitMinutesText
            self.scoreText = scoreText
            self.currency = currency
            self.name = name
            self.region = region
            self.priorityText = priorityText
            self.ownerID = ownerID
            self.windowDays = windowDays
            self.payerText = payerText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCareProtocolRuleView(_ item: RollingCareProtocolRule) -> RollingCareProtocolRuleView {
        return RollingCareProtocolRuleView(
            code: item.code,
            titleText: item.title,
            visitMinutesText: String(item.visitMinutes),
            scoreText: String(format: "%.2f", item.score),
            currency: item.currency,
            name: item.name,
            region: item.region,
            priorityText: String(item.priority),
            ownerID: item.ownerID,
            windowDays: String(item.windowDays),
            payerText: Kit.Text.truncate(item.payer, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCareProtocolRuleViews(_ items: [RollingCareProtocolRule]) -> [RollingCareProtocolRuleView] {
        var views: [RollingCareProtocolRuleView] = []
        for item in items {
            views.append(toRollingCareProtocolRuleView(item))
        }
        return views
    }

    static func sumRollingCareProtocolRuleView(_ view: RollingCareProtocolRuleView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedVisitMinutes) + parsedScore + Double(parsedPriority)
    }
}
