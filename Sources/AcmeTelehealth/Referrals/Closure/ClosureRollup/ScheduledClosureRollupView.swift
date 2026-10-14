import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a scheduled closure rollup.
    final class ScheduledClosureRollupView {
        var code: String
        var titleText: String
        var weight: String
        var currency: String
        var payer: String
        var channel: String
        var encounterID: String
        var statusLabel: String

        init(code: String, titleText: String, weight: String, currency: String, payer: String, channel: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.weight = weight
            self.currency = currency
            self.payer = payer
            self.channel = channel
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledClosureRollupView(_ item: ScheduledClosureRollup) -> ScheduledClosureRollupView {
        return ScheduledClosureRollupView(
            code: item.code,
            titleText: item.title,
            weight: String(format: "%.2f", item.weight),
            currency: item.currency,
            payer: item.payer,
            channel: item.channel,
            encounterID: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledClosureRollupViews(_ items: [ScheduledClosureRollup]) -> [ScheduledClosureRollupView] {
        var views: [ScheduledClosureRollupView] = []
        for item in items {
            views.append(toScheduledClosureRollupView(item))
        }
        return views
    }

    static func sumScheduledClosureRollupView(_ view: ScheduledClosureRollupView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
