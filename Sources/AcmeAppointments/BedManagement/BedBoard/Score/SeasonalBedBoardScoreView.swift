import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a seasonal bed board score.
    final class SeasonalBedBoardScoreView {
        var code: String
        var titleText: String
        var windowDaysText: String
        var maximum: String
        var statusLabel: String

        init(code: String, titleText: String, windowDaysText: String, maximum: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.windowDaysText = windowDaysText
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalBedBoardScoreView(_ item: SeasonalBedBoardScore) -> SeasonalBedBoardScoreView {
        return SeasonalBedBoardScoreView(
            code: item.code,
            titleText: item.title,
            windowDaysText: String(item.windowDays),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalBedBoardScoreViews(_ items: [SeasonalBedBoardScore]) -> [SeasonalBedBoardScoreView] {
        var views: [SeasonalBedBoardScoreView] = []
        for item in items {
            views.append(toSeasonalBedBoardScoreView(item))
        }
        return views
    }

    static func sumSeasonalBedBoardScoreView(_ view: SeasonalBedBoardScoreView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedWindowDays) + parsedMaximum
    }
}
