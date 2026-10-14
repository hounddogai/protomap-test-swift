import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled courier tier.
    final class ScheduledCourierTierView {
        var codeText: String
        var titleText: String
        var costText: String
        var version: String
        var attempts: String
        var revision: String
        var acuity: String
        var createdAtText: String
        var region: String
        var statusLabel: String

        init(codeText: String, titleText: String, costText: String, version: String, attempts: String, revision: String, acuity: String, createdAtText: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.costText = costText
            self.version = version
            self.attempts = attempts
            self.revision = revision
            self.acuity = acuity
            self.createdAtText = createdAtText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCourierTierView(_ item: ScheduledCourierTier) -> ScheduledCourierTierView {
        return ScheduledCourierTierView(
            codeText: item.code,
            titleText: item.title,
            costText: String(format: "%.2f", item.cost),
            version: String(item.version),
            attempts: String(item.attempts),
            revision: String(item.revision),
            acuity: String(item.acuity),
            createdAtText: String(item.createdAt),
            region: Kit.Text.truncate(item.region, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCourierTierViews(_ items: [ScheduledCourierTier]) -> [ScheduledCourierTierView] {
        var views: [ScheduledCourierTierView] = []
        for item in items {
            views.append(toScheduledCourierTierView(item))
        }
        return views
    }

    static func sumScheduledCourierTierView(_ view: ScheduledCourierTierView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedCost + Double(parsedVersion) + Double(parsedAttempts)
    }
}
