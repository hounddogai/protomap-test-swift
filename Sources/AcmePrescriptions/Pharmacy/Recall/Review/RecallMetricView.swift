import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall metric.
    final class RecallMetricView {
        var code: String
        var name: String
        var visible: String
        var source: String
        var limit: String
        var specialty: String
        var titleText: String
        var statusLabel: String

        init(code: String, name: String, visible: String, source: String, limit: String, specialty: String, titleText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visible = visible
            self.source = source
            self.limit = limit
            self.specialty = specialty
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toRecallMetricView(_ item: RecallMetric) -> RecallMetricView {
        return RecallMetricView(
            code: item.code,
            name: item.name,
            visible: "\(item.visible)",
            source: item.source,
            limit: String(item.limit),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallMetricViews(_ items: [RecallMetric]) -> [RecallMetricView] {
        var views: [RecallMetricView] = []
        for item in items {
            views.append(toRecallMetricView(item))
        }
        return views
    }

    static func sumRecallMetricView(_ view: RecallMetricView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
