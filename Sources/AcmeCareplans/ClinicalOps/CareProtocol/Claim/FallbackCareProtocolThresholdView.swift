import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback care protocol threshold.
    final class FallbackCareProtocolThresholdView {
        var code: String
        var title: String
        var reviewer: String
        var sequence: String
        var bed: String
        var maximum: String
        var unit: String
        var limitText: String
        var statusLabel: String

        init(code: String, title: String, reviewer: String, sequence: String, bed: String, maximum: String, unit: String, limitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.sequence = sequence
            self.bed = bed
            self.maximum = maximum
            self.unit = unit
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCareProtocolThresholdView(_ item: FallbackCareProtocolThreshold) -> FallbackCareProtocolThresholdView {
        return FallbackCareProtocolThresholdView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            reviewer: item.reviewer,
            sequence: String(item.sequence),
            bed: item.bed,
            maximum: String(format: "%.2f", item.maximum),
            unit: item.unit,
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCareProtocolThresholdViews(_ items: [FallbackCareProtocolThreshold]) -> [FallbackCareProtocolThresholdView] {
        var views: [FallbackCareProtocolThresholdView] = []
        for item in items {
            views.append(toFallbackCareProtocolThresholdView(item))
        }
        return views
    }

    static func sumFallbackCareProtocolThresholdView(_ view: FallbackCareProtocolThresholdView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedSequence) + parsedMaximum + Double(parsedLimit)
    }
}
