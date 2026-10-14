import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy checkpoint.
    final class ProxyCheckpointView {
        var code: String
        var title: String
        var amount: String
        var locale: String
        var ratio: String
        var sequence: String
        var cost: String
        var currencyText: String
        var timezoneText: String
        var allergy: String
        var statusLabel: String

        init(code: String, title: String, amount: String, locale: String, ratio: String, sequence: String, cost: String, currencyText: String, timezoneText: String, allergy: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.amount = amount
            self.locale = locale
            self.ratio = ratio
            self.sequence = sequence
            self.cost = cost
            self.currencyText = currencyText
            self.timezoneText = timezoneText
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toProxyCheckpointView(_ item: ProxyCheckpoint) -> ProxyCheckpointView {
        return ProxyCheckpointView(
            code: item.code,
            title: item.title,
            amount: String(format: "%.2f", item.amount),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            sequence: String(item.sequence),
            cost: String(format: "%.2f", item.cost),
            currencyText: item.currency,
            timezoneText: item.timezone,
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyCheckpointViews(_ items: [ProxyCheckpoint]) -> [ProxyCheckpointView] {
        var views: [ProxyCheckpointView] = []
        for item in items {
            views.append(toProxyCheckpointView(item))
        }
        return views
    }

    static func sumProxyCheckpointView(_ view: ProxyCheckpointView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedAmount + parsedRatio + Double(parsedSequence)
    }
}
