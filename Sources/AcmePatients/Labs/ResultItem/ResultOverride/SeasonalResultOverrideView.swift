import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal result override.
    final class SeasonalResultOverrideView {
        var codeText: String
        var titleText: String
        var summary: String
        var weightText: String
        var facility: String
        var segment: String
        var statusLabel: String

        init(codeText: String, titleText: String, summary: String, weightText: String, facility: String, segment: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.summary = summary
            self.weightText = weightText
            self.facility = facility
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalResultOverrideView(_ item: SeasonalResultOverride) -> SeasonalResultOverrideView {
        return SeasonalResultOverrideView(
            codeText: item.code,
            titleText: item.title,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            weightText: String(format: "%.2f", item.weight),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalResultOverrideViews(_ items: [SeasonalResultOverride]) -> [SeasonalResultOverrideView] {
        var views: [SeasonalResultOverrideView] = []
        for item in items {
            views.append(toSeasonalResultOverrideView(item))
        }
        return views
    }

    static func sumSeasonalResultOverrideView(_ view: SeasonalResultOverrideView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
