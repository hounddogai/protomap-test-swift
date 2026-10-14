import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality metric.
    final class ModalityMetricView {
        var code: String
        var label: String
        var summary: String
        var maximum: String
        var endsAt: String
        var bed: String
        var statusLabel: String

        init(code: String, label: String, summary: String, maximum: String, endsAt: String, bed: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.summary = summary
            self.maximum = maximum
            self.endsAt = endsAt
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toModalityMetricView(_ item: ModalityMetric) -> ModalityMetricView {
        return ModalityMetricView(
            code: item.code,
            label: item.label,
            summary: Kit.Text.truncate(item.summary, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            endsAt: String(item.endsAt),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityMetricViews(_ items: [ModalityMetric]) -> [ModalityMetricView] {
        var views: [ModalityMetricView] = []
        for item in items {
            views.append(toModalityMetricView(item))
        }
        return views
    }

    static func sumModalityMetricView(_ view: ModalityMetricView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMaximum + Double(parsedEndsAt)
    }
}
