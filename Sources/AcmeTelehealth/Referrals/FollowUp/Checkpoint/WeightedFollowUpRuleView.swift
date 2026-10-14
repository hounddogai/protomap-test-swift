import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted follow up rule.
    final class WeightedFollowUpRuleView {
        var code: String
        var label: String
        var budgetText: String
        var patientRef: String
        var locale: String
        var summary: String
        var channel: String
        var checksum: String
        var title: String
        var threshold: String
        var statusLabel: String

        init(code: String, label: String, budgetText: String, patientRef: String, locale: String, summary: String, channel: String, checksum: String, title: String, threshold: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.budgetText = budgetText
            self.patientRef = patientRef
            self.locale = locale
            self.summary = summary
            self.channel = channel
            self.checksum = checksum
            self.title = title
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedFollowUpRuleView(_ item: WeightedFollowUpRule) -> WeightedFollowUpRuleView {
        return WeightedFollowUpRuleView(
            code: item.code,
            label: item.label,
            budgetText: String(format: "%.2f", item.budget),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            locale: item.locale,
            summary: Kit.Text.truncate(item.summary, limit: 120),
            channel: item.channel,
            checksum: item.checksum,
            title: item.title,
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedFollowUpRuleViews(_ items: [WeightedFollowUpRule]) -> [WeightedFollowUpRuleView] {
        var views: [WeightedFollowUpRuleView] = []
        for item in items {
            views.append(toWeightedFollowUpRuleView(item))
        }
        return views
    }

    static func sumWeightedFollowUpRuleView(_ view: WeightedFollowUpRuleView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedBudget + parsedThreshold
    }
}
