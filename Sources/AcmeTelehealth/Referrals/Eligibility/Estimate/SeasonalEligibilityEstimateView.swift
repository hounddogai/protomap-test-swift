import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal eligibility estimate.
    final class SeasonalEligibilityEstimateView {
        var code: String
        var titleText: String
        var labelText: String
        var startsAt: String
        var limit: String
        var statusLabel: String

        init(code: String, titleText: String, labelText: String, startsAt: String, limit: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.labelText = labelText
            self.startsAt = startsAt
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalEligibilityEstimateView(_ item: SeasonalEligibilityEstimate) -> SeasonalEligibilityEstimateView {
        return SeasonalEligibilityEstimateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            startsAt: String(item.startsAt),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalEligibilityEstimateViews(_ items: [SeasonalEligibilityEstimate]) -> [SeasonalEligibilityEstimateView] {
        var views: [SeasonalEligibilityEstimateView] = []
        for item in items {
            views.append(toSeasonalEligibilityEstimateView(item))
        }
        return views
    }

    static func sumSeasonalEligibilityEstimateView(_ view: SeasonalEligibilityEstimateView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedLimit)
    }
}
