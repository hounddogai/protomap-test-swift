import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional courier metric.
    final class RegionalCourierMetricView {
        var code: String
        var label: String
        var visibleText: String
        var category: String
        var discount: String
        var bed: String
        var refills: String
        var checksumText: String
        var segment: String
        var statusLabel: String

        init(code: String, label: String, visibleText: String, category: String, discount: String, bed: String, refills: String, checksumText: String, segment: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visibleText = visibleText
            self.category = category
            self.discount = discount
            self.bed = bed
            self.refills = refills
            self.checksumText = checksumText
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCourierMetricView(_ item: RegionalCourierMetric) -> RegionalCourierMetricView {
        return RegionalCourierMetricView(
            code: item.code,
            label: item.label,
            visibleText: "\(item.visible)",
            category: item.category,
            discount: String(format: "%.2f", item.discount),
            bed: item.bed,
            refills: String(item.refills),
            checksumText: item.checksum,
            segment: Kit.Text.truncate(item.segment, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCourierMetricViews(_ items: [RegionalCourierMetric]) -> [RegionalCourierMetricView] {
        var views: [RegionalCourierMetricView] = []
        for item in items {
            views.append(toRegionalCourierMetricView(item))
        }
        return views
    }

    static func sumRegionalCourierMetricView(_ view: RegionalCourierMetricView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedDiscount + Double(parsedRefills)
    }
}
