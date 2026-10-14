import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional care gap variance.
    final class RegionalCareGapVarianceView {
        var code: String
        var label: String
        var expiresAt: String
        var currency: String
        var budgetText: String
        var minimum: String
        var channel: String
        var facilityText: String
        var capacityText: String
        var statusLabel: String

        init(code: String, label: String, expiresAt: String, currency: String, budgetText: String, minimum: String, channel: String, facilityText: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.currency = currency
            self.budgetText = budgetText
            self.minimum = minimum
            self.channel = channel
            self.facilityText = facilityText
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCareGapVarianceView(_ item: RegionalCareGapVariance) -> RegionalCareGapVarianceView {
        return RegionalCareGapVarianceView(
            code: item.code,
            label: item.label,
            expiresAt: String(item.expiresAt),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            budgetText: String(format: "%.2f", item.budget),
            minimum: String(format: "%.2f", item.minimum),
            channel: item.channel,
            facilityText: item.facility,
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCareGapVarianceViews(_ items: [RegionalCareGapVariance]) -> [RegionalCareGapVarianceView] {
        var views: [RegionalCareGapVarianceView] = []
        for item in items {
            views.append(toRegionalCareGapVarianceView(item))
        }
        return views
    }

    static func sumRegionalCareGapVarianceView(_ view: RegionalCareGapVarianceView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedExpiresAt) + parsedBudget + parsedMinimum
    }
}
