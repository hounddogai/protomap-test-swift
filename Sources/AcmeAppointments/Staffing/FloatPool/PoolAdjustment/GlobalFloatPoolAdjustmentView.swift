import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global float pool adjustment.
    final class GlobalFloatPoolAdjustmentView {
        var codeText: String
        var label: String
        var floorValueText: String
        var quantity: String
        var minimum: String
        var visitMinutes: String
        var ownerID: String
        var attempts: String
        var currency: String
        var retries: String
        var rate: String
        var statusLabel: String

        init(codeText: String, label: String, floorValueText: String, quantity: String, minimum: String, visitMinutes: String, ownerID: String, attempts: String, currency: String, retries: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.floorValueText = floorValueText
            self.quantity = quantity
            self.minimum = minimum
            self.visitMinutes = visitMinutes
            self.ownerID = ownerID
            self.attempts = attempts
            self.currency = currency
            self.retries = retries
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalFloatPoolAdjustmentView(_ item: GlobalFloatPoolAdjustment) -> GlobalFloatPoolAdjustmentView {
        return GlobalFloatPoolAdjustmentView(
            codeText: item.code,
            label: item.label,
            floorValueText: String(format: "%.2f", item.floorValue),
            quantity: String(item.quantity),
            minimum: String(format: "%.2f", item.minimum),
            visitMinutes: String(item.visitMinutes),
            ownerID: item.ownerID,
            attempts: String(item.attempts),
            currency: item.currency,
            retries: String(item.retries),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalFloatPoolAdjustmentViews(_ items: [GlobalFloatPoolAdjustment]) -> [GlobalFloatPoolAdjustmentView] {
        var views: [GlobalFloatPoolAdjustmentView] = []
        for item in items {
            views.append(toGlobalFloatPoolAdjustmentView(item))
        }
        return views
    }

    static func sumGlobalFloatPoolAdjustmentView(_ view: GlobalFloatPoolAdjustmentView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedFloorValue + Double(parsedQuantity) + parsedMinimum
    }
}
