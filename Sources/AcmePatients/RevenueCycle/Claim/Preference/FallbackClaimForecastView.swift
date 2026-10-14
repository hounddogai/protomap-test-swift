import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a fallback claim forecast.
    final class FallbackClaimForecastView {
        var code: String
        var nameText: String
        var patientRef: String
        var expiresAt: String
        var bed: String
        var updatedAt: String
        var discountText: String
        var quantityText: String
        var ratio: String
        var statusLabel: String

        init(code: String, nameText: String, patientRef: String, expiresAt: String, bed: String, updatedAt: String, discountText: String, quantityText: String, ratio: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.bed = bed
            self.updatedAt = updatedAt
            self.discountText = discountText
            self.quantityText = quantityText
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackClaimForecastView(_ item: FallbackClaimForecast) -> FallbackClaimForecastView {
        return FallbackClaimForecastView(
            code: item.code,
            nameText: item.name,
            patientRef: item.patientRef,
            expiresAt: String(item.expiresAt),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            updatedAt: String(item.updatedAt),
            discountText: String(format: "%.2f", item.discount),
            quantityText: String(item.quantity),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackClaimForecastViews(_ items: [FallbackClaimForecast]) -> [FallbackClaimForecastView] {
        var views: [FallbackClaimForecastView] = []
        for item in items {
            views.append(toFallbackClaimForecastView(item))
        }
        return views
    }

    static func sumFallbackClaimForecastView(_ view: FallbackClaimForecastView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedUpdatedAt) + parsedDiscount
    }
}
