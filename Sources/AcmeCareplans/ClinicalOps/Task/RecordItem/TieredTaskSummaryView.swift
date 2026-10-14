import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered task summary.
    final class TieredTaskSummaryView {
        var code: String
        var title: String
        var country: String
        var startsAt: String
        var attempts: String
        var cost: String
        var statusLabel: String

        init(code: String, title: String, country: String, startsAt: String, attempts: String, cost: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.country = country
            self.startsAt = startsAt
            self.attempts = attempts
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toTieredTaskSummaryView(_ item: TieredTaskSummary) -> TieredTaskSummaryView {
        return TieredTaskSummaryView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            country: Kit.Text.truncate(item.country, limit: 80),
            startsAt: String(item.startsAt),
            attempts: String(item.attempts),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredTaskSummaryViews(_ items: [TieredTaskSummary]) -> [TieredTaskSummaryView] {
        var views: [TieredTaskSummaryView] = []
        for item in items {
            views.append(toTieredTaskSummaryView(item))
        }
        return views
    }

    static func sumTieredTaskSummaryView(_ view: TieredTaskSummaryView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedAttempts) + parsedCost
    }
}
