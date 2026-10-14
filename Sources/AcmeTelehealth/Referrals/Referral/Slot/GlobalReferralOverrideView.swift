import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global referral override.
    final class GlobalReferralOverrideView {
        var code: String
        var title: String
        var weight: String
        var channel: String
        var notes: String
        var expiresAt: String
        var summary: String
        var createdAt: String
        var statusLabel: String

        init(code: String, title: String, weight: String, channel: String, notes: String, expiresAt: String, summary: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.weight = weight
            self.channel = channel
            self.notes = notes
            self.expiresAt = expiresAt
            self.summary = summary
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalReferralOverrideView(_ item: GlobalReferralOverride) -> GlobalReferralOverrideView {
        return GlobalReferralOverrideView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 120),
            weight: String(format: "%.2f", item.weight),
            channel: item.channel,
            notes: Kit.Text.truncate(item.notes, limit: 40),
            expiresAt: String(item.expiresAt),
            summary: item.summary,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalReferralOverrideViews(_ items: [GlobalReferralOverride]) -> [GlobalReferralOverrideView] {
        var views: [GlobalReferralOverrideView] = []
        for item in items {
            views.append(toGlobalReferralOverrideView(item))
        }
        return views
    }

    static func sumGlobalReferralOverrideView(_ view: GlobalReferralOverrideView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedWeight + Double(parsedExpiresAt) + Double(parsedCreatedAt)
    }
}
