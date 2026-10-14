import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up quota.
    final class FollowUpQuotaView {
        var code: String
        var label: String
        var contactEmail: String
        var description: String
        var version: String
        var segment: String
        var channel: String
        var categoryText: String
        var currency: String
        var amountText: String
        var statusLabel: String

        init(code: String, label: String, contactEmail: String, description: String, version: String, segment: String, channel: String, categoryText: String, currency: String, amountText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.description = description
            self.version = version
            self.segment = segment
            self.channel = channel
            self.categoryText = categoryText
            self.currency = currency
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpQuotaView(_ item: FollowUpQuota) -> FollowUpQuotaView {
        return FollowUpQuotaView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            contactEmail: item.contactEmail,
            description: item.description,
            version: String(item.version),
            segment: item.segment,
            channel: item.channel,
            categoryText: item.category,
            currency: item.currency,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpQuotaViews(_ items: [FollowUpQuota]) -> [FollowUpQuotaView] {
        var views: [FollowUpQuotaView] = []
        for item in items {
            views.append(toFollowUpQuotaView(item))
        }
        return views
    }

    static func sumFollowUpQuotaView(_ view: FollowUpQuotaView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedVersion) + parsedAmount
    }
}
