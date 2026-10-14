import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal handoff threshold.
    final class SeasonalHandoffThresholdView {
        var codeText: String
        var label: String
        var segment: String
        var ratioText: String
        var retriesText: String
        var weightText: String
        var statusLabel: String

        init(codeText: String, label: String, segment: String, ratioText: String, retriesText: String, weightText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.segment = segment
            self.ratioText = ratioText
            self.retriesText = retriesText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalHandoffThresholdView(_ item: SeasonalHandoffThreshold) -> SeasonalHandoffThresholdView {
        return SeasonalHandoffThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            segment: item.segment,
            ratioText: String(format: "%.2f", item.ratio),
            retriesText: String(item.retries),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalHandoffThresholdViews(_ items: [SeasonalHandoffThreshold]) -> [SeasonalHandoffThresholdView] {
        var views: [SeasonalHandoffThresholdView] = []
        for item in items {
            views.append(toSeasonalHandoffThresholdView(item))
        }
        return views
    }

    static func sumSeasonalHandoffThresholdView(_ view: SeasonalHandoffThresholdView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedRatio + Double(parsedRetries) + parsedWeight
    }
}
