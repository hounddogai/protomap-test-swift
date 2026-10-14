import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling discharge plan summary.
    final class RollingDischargePlanSummaryView {
        var code: String
        var titleText: String
        var windowDaysText: String
        var attempts: String
        var score: String
        var marginText: String
        var ratio: String
        var reviewer: String
        var statusLabel: String

        init(code: String, titleText: String, windowDaysText: String, attempts: String, score: String, marginText: String, ratio: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.windowDaysText = windowDaysText
            self.attempts = attempts
            self.score = score
            self.marginText = marginText
            self.ratio = ratio
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDischargePlanSummaryView(_ item: RollingDischargePlanSummary) -> RollingDischargePlanSummaryView {
        return RollingDischargePlanSummaryView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            windowDaysText: String(item.windowDays),
            attempts: String(item.attempts),
            score: String(format: "%.2f", item.score),
            marginText: String(format: "%.2f", item.margin),
            ratio: String(format: "%.2f", item.ratio),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDischargePlanSummaryViews(_ items: [RollingDischargePlanSummary]) -> [RollingDischargePlanSummaryView] {
        var views: [RollingDischargePlanSummaryView] = []
        for item in items {
            views.append(toRollingDischargePlanSummaryView(item))
        }
        return views
    }

    static func sumRollingDischargePlanSummaryView(_ view: RollingDischargePlanSummaryView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedAttempts) + parsedScore
    }
}
