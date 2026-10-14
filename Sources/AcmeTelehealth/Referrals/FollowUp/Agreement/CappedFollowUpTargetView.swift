import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped follow up target.
    final class CappedFollowUpTargetView {
        var codeText: String
        var titleText: String
        var amountText: String
        var reviewer: String
        var rate: String
        var timezoneText: String
        var channel: String
        var graceDays: String
        var checksum: String
        var contactEmailText: String
        var statusLabel: String

        init(codeText: String, titleText: String, amountText: String, reviewer: String, rate: String, timezoneText: String, channel: String, graceDays: String, checksum: String, contactEmailText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.amountText = amountText
            self.reviewer = reviewer
            self.rate = rate
            self.timezoneText = timezoneText
            self.channel = channel
            self.graceDays = graceDays
            self.checksum = checksum
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedFollowUpTargetView(_ item: CappedFollowUpTarget) -> CappedFollowUpTargetView {
        return CappedFollowUpTargetView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            amountText: String(format: "%.2f", item.amount),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            rate: String(format: "%.2f", item.rate),
            timezoneText: item.timezone,
            channel: item.channel,
            graceDays: String(item.graceDays),
            checksum: item.checksum,
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedFollowUpTargetViews(_ items: [CappedFollowUpTarget]) -> [CappedFollowUpTargetView] {
        var views: [CappedFollowUpTargetView] = []
        for item in items {
            views.append(toCappedFollowUpTargetView(item))
        }
        return views
    }

    static func sumCappedFollowUpTargetView(_ view: CappedFollowUpTargetView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedAmount + parsedRate + Double(parsedGraceDays)
    }
}
