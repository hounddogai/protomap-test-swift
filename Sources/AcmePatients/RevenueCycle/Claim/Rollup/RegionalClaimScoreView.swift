import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional claim score.
    final class RegionalClaimScoreView {
        var code: String
        var labelText: String
        var summary: String
        var minimum: String
        var segmentText: String
        var channel: String
        var countryText: String
        var statusLabel: String

        init(code: String, labelText: String, summary: String, minimum: String, segmentText: String, channel: String, countryText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.summary = summary
            self.minimum = minimum
            self.segmentText = segmentText
            self.channel = channel
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalClaimScoreView(_ item: RegionalClaimScore) -> RegionalClaimScoreView {
        return RegionalClaimScoreView(
            code: item.code,
            labelText: item.label,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            minimum: String(format: "%.2f", item.minimum),
            segmentText: item.segment,
            channel: item.channel,
            countryText: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalClaimScoreViews(_ items: [RegionalClaimScore]) -> [RegionalClaimScoreView] {
        var views: [RegionalClaimScoreView] = []
        for item in items {
            views.append(toRegionalClaimScoreView(item))
        }
        return views
    }

    static func sumRegionalClaimScoreView(_ view: RegionalClaimScoreView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
