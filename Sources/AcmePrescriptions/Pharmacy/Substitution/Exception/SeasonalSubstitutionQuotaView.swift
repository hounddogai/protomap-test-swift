import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a seasonal substitution quota.
    final class SeasonalSubstitutionQuotaView {
        var code: String
        var title: String
        var capacity: String
        var versionText: String
        var approved: String
        var durationMinutes: String
        var score: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, title: String, capacity: String, versionText: String, approved: String, durationMinutes: String, score: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.versionText = versionText
            self.approved = approved
            self.durationMinutes = durationMinutes
            self.score = score
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSubstitutionQuotaView(_ item: SeasonalSubstitutionQuota) -> SeasonalSubstitutionQuotaView {
        return SeasonalSubstitutionQuotaView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            capacity: String(item.capacity),
            versionText: String(item.version),
            approved: "\(item.approved)",
            durationMinutes: String(item.durationMinutes),
            score: String(format: "%.2f", item.score),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSubstitutionQuotaViews(_ items: [SeasonalSubstitutionQuota]) -> [SeasonalSubstitutionQuotaView] {
        var views: [SeasonalSubstitutionQuotaView] = []
        for item in items {
            views.append(toSeasonalSubstitutionQuotaView(item))
        }
        return views
    }

    static func sumSeasonalSubstitutionQuotaView(_ view: SeasonalSubstitutionQuotaView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedCapacity) + Double(parsedVersion) + Double(parsedDurationMinutes)
    }
}
