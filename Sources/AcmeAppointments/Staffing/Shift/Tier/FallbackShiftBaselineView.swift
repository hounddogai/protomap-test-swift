import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback shift baseline.
    final class FallbackShiftBaselineView {
        var code: String
        var name: String
        var unitText: String
        var thresholdText: String
        var expiresAt: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, unitText: String, thresholdText: String, expiresAt: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unitText = unitText
            self.thresholdText = thresholdText
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackShiftBaselineView(_ item: FallbackShiftBaseline) -> FallbackShiftBaselineView {
        return FallbackShiftBaselineView(
            code: item.code,
            name: item.name,
            unitText: item.unit,
            thresholdText: String(format: "%.2f", item.threshold),
            expiresAt: String(item.expiresAt),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackShiftBaselineViews(_ items: [FallbackShiftBaseline]) -> [FallbackShiftBaselineView] {
        var views: [FallbackShiftBaselineView] = []
        for item in items {
            views.append(toFallbackShiftBaselineView(item))
        }
        return views
    }

    static func sumFallbackShiftBaselineView(_ view: FallbackShiftBaselineView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedThreshold + Double(parsedExpiresAt) + Double(parsedQuantity)
    }
}
