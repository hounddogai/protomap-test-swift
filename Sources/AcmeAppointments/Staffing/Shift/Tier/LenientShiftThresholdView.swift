import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient shift threshold.
    final class LenientShiftThresholdView {
        var code: String
        var name: String
        var batchSize: String
        var timezone: String
        var region: String
        var quantity: String
        var bed: String
        var locale: String
        var statusLabel: String

        init(code: String, name: String, batchSize: String, timezone: String, region: String, quantity: String, bed: String, locale: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.timezone = timezone
            self.region = region
            self.quantity = quantity
            self.bed = bed
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toLenientShiftThresholdView(_ item: LenientShiftThreshold) -> LenientShiftThresholdView {
        return LenientShiftThresholdView(
            code: item.code,
            name: item.name,
            batchSize: String(item.batchSize),
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            region: item.region,
            quantity: String(item.quantity),
            bed: item.bed,
            locale: Kit.Text.truncate(item.locale, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientShiftThresholdViews(_ items: [LenientShiftThreshold]) -> [LenientShiftThresholdView] {
        var views: [LenientShiftThresholdView] = []
        for item in items {
            views.append(toLenientShiftThresholdView(item))
        }
        return views
    }

    static func sumLenientShiftThresholdView(_ view: LenientShiftThresholdView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedQuantity)
    }
}
