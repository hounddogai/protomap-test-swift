import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted courier segment.
    final class WeightedCourierSegmentView {
        var codeText: String
        var label: String
        var ratio: String
        var timezone: String
        var createdAt: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, label: String, ratio: String, timezone: String, createdAt: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ratio = ratio
            self.timezone = timezone
            self.createdAt = createdAt
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCourierSegmentView(_ item: WeightedCourierSegment) -> WeightedCourierSegmentView {
        return WeightedCourierSegmentView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            ratio: String(format: "%.2f", item.ratio),
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            createdAt: String(item.createdAt),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCourierSegmentViews(_ items: [WeightedCourierSegment]) -> [WeightedCourierSegmentView] {
        var views: [WeightedCourierSegmentView] = []
        for item in items {
            views.append(toWeightedCourierSegmentView(item))
        }
        return views
    }

    static func sumWeightedCourierSegmentView(_ view: WeightedCourierSegmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedRatio + Double(parsedCreatedAt) + parsedMaximum
    }
}
