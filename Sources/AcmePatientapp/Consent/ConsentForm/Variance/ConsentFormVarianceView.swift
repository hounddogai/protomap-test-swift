import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form variance.
    final class ConsentFormVarianceView {
        var code: String
        var label: String
        var expiresAt: String
        var quantity: String
        var weightText: String
        var attempts: String
        var statusLabel: String

        init(code: String, label: String, expiresAt: String, quantity: String, weightText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.weightText = weightText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormVarianceView(_ item: ConsentFormVariance) -> ConsentFormVarianceView {
        return ConsentFormVarianceView(
            code: item.code,
            label: item.label,
            expiresAt: String(item.expiresAt),
            quantity: String(item.quantity),
            weightText: String(format: "%.2f", item.weight),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormVarianceViews(_ items: [ConsentFormVariance]) -> [ConsentFormVarianceView] {
        var views: [ConsentFormVarianceView] = []
        for item in items {
            views.append(toConsentFormVarianceView(item))
        }
        return views
    }

    static func sumConsentFormVarianceView(_ view: ConsentFormVarianceView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedQuantity) + parsedWeight
    }
}
