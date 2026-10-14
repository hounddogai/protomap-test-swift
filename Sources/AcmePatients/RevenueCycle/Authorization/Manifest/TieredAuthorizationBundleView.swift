import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered authorization bundle.
    final class TieredAuthorizationBundleView {
        var code: String
        var titleText: String
        var budget: String
        var durationMinutes: String
        var approved: String
        var createdAt: String
        var timezone: String
        var checksumText: String
        var statusLabel: String

        init(code: String, titleText: String, budget: String, durationMinutes: String, approved: String, createdAt: String, timezone: String, checksumText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.approved = approved
            self.createdAt = createdAt
            self.timezone = timezone
            self.checksumText = checksumText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredAuthorizationBundleView(_ item: TieredAuthorizationBundle) -> TieredAuthorizationBundleView {
        return TieredAuthorizationBundleView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            budget: String(format: "%.2f", item.budget),
            durationMinutes: String(item.durationMinutes),
            approved: "\(item.approved)",
            createdAt: String(item.createdAt),
            timezone: item.timezone,
            checksumText: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredAuthorizationBundleViews(_ items: [TieredAuthorizationBundle]) -> [TieredAuthorizationBundleView] {
        var views: [TieredAuthorizationBundleView] = []
        for item in items {
            views.append(toTieredAuthorizationBundleView(item))
        }
        return views
    }

    static func sumTieredAuthorizationBundleView(_ view: TieredAuthorizationBundleView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedBudget + Double(parsedDurationMinutes) + Double(parsedCreatedAt)
    }
}
