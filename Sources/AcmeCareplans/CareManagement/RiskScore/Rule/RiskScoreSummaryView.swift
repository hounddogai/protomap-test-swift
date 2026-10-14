import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score summary.
    final class RiskScoreSummaryView {
        var code: String
        var titleText: String
        var approved: String
        var currencyText: String
        var categoryText: String
        var graceDaysText: String
        var visitMinutes: String
        var windowDays: String
        var statusLabel: String

        init(code: String, titleText: String, approved: String, currencyText: String, categoryText: String, graceDaysText: String, visitMinutes: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.approved = approved
            self.currencyText = currencyText
            self.categoryText = categoryText
            self.graceDaysText = graceDaysText
            self.visitMinutes = visitMinutes
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreSummaryView(_ item: RiskScoreSummary) -> RiskScoreSummaryView {
        return RiskScoreSummaryView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            approved: "\(item.approved)",
            currencyText: Kit.Text.truncate(item.currency, limit: 64),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            graceDaysText: String(item.graceDays),
            visitMinutes: String(item.visitMinutes),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreSummaryViews(_ items: [RiskScoreSummary]) -> [RiskScoreSummaryView] {
        var views: [RiskScoreSummaryView] = []
        for item in items {
            views.append(toRiskScoreSummaryView(item))
        }
        return views
    }

    static func sumRiskScoreSummaryView(_ view: RiskScoreSummaryView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedVisitMinutes) + Double(parsedWindowDays)
    }
}
