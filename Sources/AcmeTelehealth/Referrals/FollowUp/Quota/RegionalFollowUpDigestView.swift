import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional follow up digest.
    final class RegionalFollowUpDigestView {
        var code: String
        var title: String
        var durationMinutes: String
        var name: String
        var rate: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, title: String, durationMinutes: String, name: String, rate: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.name = name
            self.rate = rate
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalFollowUpDigestView(_ item: RegionalFollowUpDigest) -> RegionalFollowUpDigestView {
        return RegionalFollowUpDigestView(
            code: item.code,
            title: item.title,
            durationMinutes: String(item.durationMinutes),
            name: Kit.Text.truncate(item.name, limit: 120),
            rate: String(format: "%.2f", item.rate),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalFollowUpDigestViews(_ items: [RegionalFollowUpDigest]) -> [RegionalFollowUpDigestView] {
        var views: [RegionalFollowUpDigestView] = []
        for item in items {
            views.append(toRegionalFollowUpDigestView(item))
        }
        return views
    }

    static func sumRegionalFollowUpDigestView(_ view: RegionalFollowUpDigestView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedDurationMinutes) + parsedRate + Double(parsedExpiresAt)
    }
}
