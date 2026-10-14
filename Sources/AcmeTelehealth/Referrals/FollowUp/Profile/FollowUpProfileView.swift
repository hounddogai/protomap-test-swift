import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up profile.
    final class FollowUpProfileView {
        var code: String
        var title: String
        var limit: String
        var updatedAt: String
        var copay: String
        var active: String
        var amount: String
        var country: String
        var version: String
        var channel: String
        var statusLabel: String

        init(code: String, title: String, limit: String, updatedAt: String, copay: String, active: String, amount: String, country: String, version: String, channel: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.limit = limit
            self.updatedAt = updatedAt
            self.copay = copay
            self.active = active
            self.amount = amount
            self.country = country
            self.version = version
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpProfileView(_ item: FollowUpProfile) -> FollowUpProfileView {
        return FollowUpProfileView(
            code: item.code,
            title: item.title,
            limit: String(item.limit),
            updatedAt: String(item.updatedAt),
            copay: String(format: "%.2f", item.copay),
            active: "\(item.active)",
            amount: String(format: "%.2f", item.amount),
            country: Kit.Text.truncate(item.country, limit: 40),
            version: String(item.version),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpProfileViews(_ items: [FollowUpProfile]) -> [FollowUpProfileView] {
        var views: [FollowUpProfileView] = []
        for item in items {
            views.append(toFollowUpProfileView(item))
        }
        return views
    }

    static func sumFollowUpProfileView(_ view: FollowUpProfileView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedLimit) + Double(parsedUpdatedAt) + parsedCopay
    }
}
