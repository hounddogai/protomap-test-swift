import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal care protocol target.
    final class SeasonalCareProtocolTargetView {
        var code: String
        var title: String
        var version: String
        var reviewer: String
        var endsAt: String
        var active: String
        var weight: String
        var regionText: String
        var cost: String
        var statusLabel: String

        init(code: String, title: String, version: String, reviewer: String, endsAt: String, active: String, weight: String, regionText: String, cost: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.version = version
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.active = active
            self.weight = weight
            self.regionText = regionText
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareProtocolTargetView(_ item: SeasonalCareProtocolTarget) -> SeasonalCareProtocolTargetView {
        return SeasonalCareProtocolTargetView(
            code: item.code,
            title: item.title,
            version: String(item.version),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            endsAt: String(item.endsAt),
            active: "\(item.active)",
            weight: String(format: "%.2f", item.weight),
            regionText: Kit.Text.truncate(item.region, limit: 64),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareProtocolTargetViews(_ items: [SeasonalCareProtocolTarget]) -> [SeasonalCareProtocolTargetView] {
        var views: [SeasonalCareProtocolTargetView] = []
        for item in items {
            views.append(toSeasonalCareProtocolTargetView(item))
        }
        return views
    }

    static func sumSeasonalCareProtocolTargetView(_ view: SeasonalCareProtocolTargetView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedVersion) + Double(parsedEndsAt) + parsedWeight
    }
}
