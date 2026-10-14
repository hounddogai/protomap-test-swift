import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback reference range variance.
    final class FallbackReferenceRangeVarianceView {
        var code: String
        var label: String
        var ceilingText: String
        var ratioText: String
        var capacityText: String
        var titleText: String
        var specialty: String
        var regionText: String
        var statusLabel: String

        init(code: String, label: String, ceilingText: String, ratioText: String, capacityText: String, titleText: String, specialty: String, regionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceilingText = ceilingText
            self.ratioText = ratioText
            self.capacityText = capacityText
            self.titleText = titleText
            self.specialty = specialty
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackReferenceRangeVarianceView(_ item: FallbackReferenceRangeVariance) -> FallbackReferenceRangeVarianceView {
        return FallbackReferenceRangeVarianceView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            ceilingText: String(format: "%.2f", item.ceiling),
            ratioText: String(format: "%.2f", item.ratio),
            capacityText: String(item.capacity),
            titleText: item.title,
            specialty: item.specialty,
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackReferenceRangeVarianceViews(_ items: [FallbackReferenceRangeVariance]) -> [FallbackReferenceRangeVarianceView] {
        var views: [FallbackReferenceRangeVarianceView] = []
        for item in items {
            views.append(toFallbackReferenceRangeVarianceView(item))
        }
        return views
    }

    static func sumFallbackReferenceRangeVarianceView(_ view: FallbackReferenceRangeVarianceView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCeiling + parsedRatio + Double(parsedCapacity)
    }
}
