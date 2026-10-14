import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance summary.
    final class RemittanceSummaryView {
        var code: String
        var label: String
        var timezone: String
        var region: String
        var encounterIDText: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, timezone: String, region: String, encounterIDText: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.region = region
            self.encounterIDText = encounterIDText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceSummaryView(_ item: RemittanceSummary) -> RemittanceSummaryView {
        return RemittanceSummaryView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            timezone: item.timezone,
            region: item.region,
            encounterIDText: item.encounterID,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceSummaryViews(_ items: [RemittanceSummary]) -> [RemittanceSummaryView] {
        var views: [RemittanceSummaryView] = []
        for item in items {
            views.append(toRemittanceSummaryView(item))
        }
        return views
    }

    static func sumRemittanceSummaryView(_ view: RemittanceSummaryView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
