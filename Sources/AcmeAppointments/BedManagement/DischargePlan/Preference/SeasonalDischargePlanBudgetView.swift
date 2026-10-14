import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a seasonal discharge plan budget.
    final class SeasonalDischargePlanBudgetView {
        var code: String
        var name: String
        var startsAtText: String
        var retries: String
        var pinned: String
        var revision: String
        var refillsText: String
        var statusLabel: String

        init(code: String, name: String, startsAtText: String, retries: String, pinned: String, revision: String, refillsText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAtText = startsAtText
            self.retries = retries
            self.pinned = pinned
            self.revision = revision
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalDischargePlanBudgetView(_ item: SeasonalDischargePlanBudget) -> SeasonalDischargePlanBudgetView {
        return SeasonalDischargePlanBudgetView(
            code: item.code,
            name: item.name,
            startsAtText: String(item.startsAt),
            retries: String(item.retries),
            pinned: "\(item.pinned)",
            revision: String(item.revision),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalDischargePlanBudgetViews(_ items: [SeasonalDischargePlanBudget]) -> [SeasonalDischargePlanBudgetView] {
        var views: [SeasonalDischargePlanBudgetView] = []
        for item in items {
            views.append(toSeasonalDischargePlanBudgetView(item))
        }
        return views
    }

    static func sumSeasonalDischargePlanBudgetView(_ view: SeasonalDischargePlanBudgetView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedRetries) + Double(parsedRevision)
    }
}
