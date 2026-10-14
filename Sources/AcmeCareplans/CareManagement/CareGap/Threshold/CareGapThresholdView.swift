import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap threshold.
    final class CareGapThresholdView {
        var code: String
        var name: String
        var quantityText: String
        var source: String
        var statusLabel: String

        init(code: String, name: String, quantityText: String, source: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantityText = quantityText
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapThresholdView(_ item: CareGapThreshold) -> CareGapThresholdView {
        return CareGapThresholdView(
            code: item.code,
            name: item.name,
            quantityText: String(item.quantity),
            source: Kit.Text.truncate(item.source, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapThresholdViews(_ items: [CareGapThreshold]) -> [CareGapThresholdView] {
        var views: [CareGapThresholdView] = []
        for item in items {
            views.append(toCareGapThresholdView(item))
        }
        return views
    }

    static func sumCareGapThresholdView(_ view: CareGapThresholdView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
