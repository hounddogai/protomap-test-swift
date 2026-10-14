import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge request.
    final class ChargeRequestView {
        var code: String
        var labelText: String
        var maximum: String
        var timezone: String
        var limit: String
        var channel: String
        var amountText: String
        var capacity: String
        var attempts: String
        var statusLabel: String

        init(code: String, labelText: String, maximum: String, timezone: String, limit: String, channel: String, amountText: String, capacity: String, attempts: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.maximum = maximum
            self.timezone = timezone
            self.limit = limit
            self.channel = channel
            self.amountText = amountText
            self.capacity = capacity
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toChargeRequestView(_ item: ChargeRequest) -> ChargeRequestView {
        return ChargeRequestView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            timezone: item.timezone,
            limit: String(item.limit),
            channel: item.channel,
            amountText: String(format: "%.2f", item.amount),
            capacity: String(item.capacity),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeRequestViews(_ items: [ChargeRequest]) -> [ChargeRequestView] {
        var views: [ChargeRequestView] = []
        for item in items {
            views.append(toChargeRequestView(item))
        }
        return views
    }

    static func sumChargeRequestView(_ view: ChargeRequestView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedMaximum + Double(parsedLimit) + parsedAmount
    }
}
