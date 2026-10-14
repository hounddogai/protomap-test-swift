import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession metric.
    final class AccessionMetricView {
        var code: String
        var titleText: String
        var notesText: String
        var capacity: String
        var bed: String
        var rate: String
        var statusLabel: String

        init(code: String, titleText: String, notesText: String, capacity: String, bed: String, rate: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.notesText = notesText
            self.capacity = capacity
            self.bed = bed
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionMetricView(_ item: AccessionMetric) -> AccessionMetricView {
        return AccessionMetricView(
            code: item.code,
            titleText: item.title,
            notesText: item.notes,
            capacity: String(item.capacity),
            bed: item.bed,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionMetricViews(_ items: [AccessionMetric]) -> [AccessionMetricView] {
        var views: [AccessionMetricView] = []
        for item in items {
            views.append(toAccessionMetricView(item))
        }
        return views
    }

    static func sumAccessionMetricView(_ view: AccessionMetricView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedCapacity) + parsedRate
    }
}
