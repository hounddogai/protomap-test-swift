import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback census metric.
    final class FallbackCensusMetricView {
        var code: String
        var name: String
        var title: String
        var clinicianID: String
        var ratioText: String
        var refills: String
        var allergy: String
        var statusLabel: String

        init(code: String, name: String, title: String, clinicianID: String, ratioText: String, refills: String, allergy: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.title = title
            self.clinicianID = clinicianID
            self.ratioText = ratioText
            self.refills = refills
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCensusMetricView(_ item: FallbackCensusMetric) -> FallbackCensusMetricView {
        return FallbackCensusMetricView(
            code: item.code,
            name: item.name,
            title: item.title,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            ratioText: String(format: "%.2f", item.ratio),
            refills: String(item.refills),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCensusMetricViews(_ items: [FallbackCensusMetric]) -> [FallbackCensusMetricView] {
        var views: [FallbackCensusMetricView] = []
        for item in items {
            views.append(toFallbackCensusMetricView(item))
        }
        return views
    }

    static func sumFallbackCensusMetricView(_ view: FallbackCensusMetricView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedRatio + Double(parsedRefills)
    }
}
