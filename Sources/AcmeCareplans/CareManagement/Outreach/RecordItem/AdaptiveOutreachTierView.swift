import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive outreach tier.
    final class AdaptiveOutreachTierView {
        var code: String
        var title: String
        var region: String
        var priorityText: String
        var description: String
        var pinned: String
        var startsAt: String
        var costText: String
        var statusLabel: String

        init(code: String, title: String, region: String, priorityText: String, description: String, pinned: String, startsAt: String, costText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.region = region
            self.priorityText = priorityText
            self.description = description
            self.pinned = pinned
            self.startsAt = startsAt
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveOutreachTierView(_ item: AdaptiveOutreachTier) -> AdaptiveOutreachTierView {
        return AdaptiveOutreachTierView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            region: Kit.Text.truncate(item.region, limit: 64),
            priorityText: String(item.priority),
            description: item.description,
            pinned: "\(item.pinned)",
            startsAt: String(item.startsAt),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveOutreachTierViews(_ items: [AdaptiveOutreachTier]) -> [AdaptiveOutreachTierView] {
        var views: [AdaptiveOutreachTierView] = []
        for item in items {
            views.append(toAdaptiveOutreachTierView(item))
        }
        return views
    }

    static func sumAdaptiveOutreachTierView(_ view: AdaptiveOutreachTierView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedPriority) + Double(parsedStartsAt) + parsedCost
    }
}
