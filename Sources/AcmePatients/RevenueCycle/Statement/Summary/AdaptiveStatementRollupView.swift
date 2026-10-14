import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive statement rollup.
    final class AdaptiveStatementRollupView {
        var code: String
        var title: String
        var refillsText: String
        var archived: String
        var windowDays: String
        var startsAt: String
        var allergyText: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, title: String, refillsText: String, archived: String, windowDays: String, startsAt: String, allergyText: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refillsText = refillsText
            self.archived = archived
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.allergyText = allergyText
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveStatementRollupView(_ item: AdaptiveStatementRollup) -> AdaptiveStatementRollupView {
        return AdaptiveStatementRollupView(
            code: item.code,
            title: item.title,
            refillsText: String(item.refills),
            archived: "\(item.archived)",
            windowDays: String(item.windowDays),
            startsAt: String(item.startsAt),
            allergyText: Kit.Text.truncate(item.allergy, limit: 64),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveStatementRollupViews(_ items: [AdaptiveStatementRollup]) -> [AdaptiveStatementRollupView] {
        var views: [AdaptiveStatementRollupView] = []
        for item in items {
            views.append(toAdaptiveStatementRollupView(item))
        }
        return views
    }

    static func sumAdaptiveStatementRollupView(_ view: AdaptiveStatementRollupView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedRefills) + Double(parsedWindowDays) + Double(parsedStartsAt)
    }
}
