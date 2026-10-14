import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient follow up target.
    final class LenientFollowUpTargetView {
        var code: String
        var title: String
        var marginText: String
        var updatedAt: String
        var attempts: String
        var version: String
        var graceDaysText: String
        var source: String
        var channel: String
        var phoneText: String
        var costText: String
        var statusLabel: String

        init(code: String, title: String, marginText: String, updatedAt: String, attempts: String, version: String, graceDaysText: String, source: String, channel: String, phoneText: String, costText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.marginText = marginText
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.version = version
            self.graceDaysText = graceDaysText
            self.source = source
            self.channel = channel
            self.phoneText = phoneText
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientFollowUpTargetView(_ item: LenientFollowUpTarget) -> LenientFollowUpTargetView {
        return LenientFollowUpTargetView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            marginText: String(format: "%.2f", item.margin),
            updatedAt: String(item.updatedAt),
            attempts: String(item.attempts),
            version: String(item.version),
            graceDaysText: String(item.graceDays),
            source: item.source,
            channel: item.channel,
            phoneText: item.phone,
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientFollowUpTargetViews(_ items: [LenientFollowUpTarget]) -> [LenientFollowUpTargetView] {
        var views: [LenientFollowUpTargetView] = []
        for item in items {
            views.append(toLenientFollowUpTargetView(item))
        }
        return views
    }

    static func sumLenientFollowUpTargetView(_ view: LenientFollowUpTargetView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedMargin + Double(parsedUpdatedAt) + Double(parsedAttempts)
    }
}
