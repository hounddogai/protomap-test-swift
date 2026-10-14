import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding window.
    final class RoundingWindowView {
        var code: String
        var label: String
        var threshold: String
        var category: String
        var ceilingText: String
        var segmentText: String
        var payer: String
        var weight: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, category: String, ceilingText: String, segmentText: String, payer: String, weight: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.category = category
            self.ceilingText = ceilingText
            self.segmentText = segmentText
            self.payer = payer
            self.weight = weight
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingWindowView(_ item: RoundingWindow) -> RoundingWindowView {
        return RoundingWindowView(
            code: item.code,
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            category: Kit.Text.truncate(item.category, limit: 40),
            ceilingText: String(format: "%.2f", item.ceiling),
            segmentText: item.segment,
            payer: Kit.Text.truncate(item.payer, limit: 40),
            weight: String(format: "%.2f", item.weight),
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingWindowViews(_ items: [RoundingWindow]) -> [RoundingWindowView] {
        var views: [RoundingWindowView] = []
        for item in items {
            views.append(toRoundingWindowView(item))
        }
        return views
    }

    static func sumRoundingWindowView(_ view: RoundingWindowView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedThreshold + parsedCeiling + parsedWeight
    }
}
