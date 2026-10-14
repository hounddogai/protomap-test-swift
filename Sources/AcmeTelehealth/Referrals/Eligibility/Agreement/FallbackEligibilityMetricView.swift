import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback eligibility metric.
    final class FallbackEligibilityMetricView {
        var code: String
        var name: String
        var batchSizeText: String
        var floorValue: String
        var ward: String
        var currency: String
        var bedText: String
        var pinnedText: String
        var notes: String
        var visibleText: String
        var statusLabel: String

        init(code: String, name: String, batchSizeText: String, floorValue: String, ward: String, currency: String, bedText: String, pinnedText: String, notes: String, visibleText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSizeText = batchSizeText
            self.floorValue = floorValue
            self.ward = ward
            self.currency = currency
            self.bedText = bedText
            self.pinnedText = pinnedText
            self.notes = notes
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackEligibilityMetricView(_ item: FallbackEligibilityMetric) -> FallbackEligibilityMetricView {
        return FallbackEligibilityMetricView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            batchSizeText: String(item.batchSize),
            floorValue: String(format: "%.2f", item.floorValue),
            ward: item.ward,
            currency: item.currency,
            bedText: item.bed,
            pinnedText: "\(item.pinned)",
            notes: item.notes,
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackEligibilityMetricViews(_ items: [FallbackEligibilityMetric]) -> [FallbackEligibilityMetricView] {
        var views: [FallbackEligibilityMetricView] = []
        for item in items {
            views.append(toFallbackEligibilityMetricView(item))
        }
        return views
    }

    static func sumFallbackEligibilityMetricView(_ view: FallbackEligibilityMetricView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedBatchSize) + parsedFloorValue
    }
}
