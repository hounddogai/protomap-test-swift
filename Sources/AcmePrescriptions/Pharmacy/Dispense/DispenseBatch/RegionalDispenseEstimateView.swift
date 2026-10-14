import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional dispense estimate.
    final class RegionalDispenseEstimateView {
        var code: String
        var name: String
        var durationMinutes: String
        var expiresAtText: String
        var quantity: String
        var unit: String
        var capacity: String
        var score: String
        var acuity: String
        var statusLabel: String

        init(code: String, name: String, durationMinutes: String, expiresAtText: String, quantity: String, unit: String, capacity: String, score: String, acuity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.expiresAtText = expiresAtText
            self.quantity = quantity
            self.unit = unit
            self.capacity = capacity
            self.score = score
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalDispenseEstimateView(_ item: RegionalDispenseEstimate) -> RegionalDispenseEstimateView {
        return RegionalDispenseEstimateView(
            code: item.code,
            name: item.name,
            durationMinutes: String(item.durationMinutes),
            expiresAtText: String(item.expiresAt),
            quantity: String(item.quantity),
            unit: item.unit,
            capacity: String(item.capacity),
            score: String(format: "%.2f", item.score),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalDispenseEstimateViews(_ items: [RegionalDispenseEstimate]) -> [RegionalDispenseEstimateView] {
        var views: [RegionalDispenseEstimateView] = []
        for item in items {
            views.append(toRegionalDispenseEstimateView(item))
        }
        return views
    }

    static func sumRegionalDispenseEstimateView(_ view: RegionalDispenseEstimateView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedExpiresAt) + Double(parsedQuantity)
    }
}
