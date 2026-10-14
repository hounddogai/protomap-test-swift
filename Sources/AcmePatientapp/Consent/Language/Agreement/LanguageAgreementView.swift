import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language agreement.
    final class LanguageAgreementView {
        var code: String
        var label: String
        var name: String
        var region: String
        var quantity: String
        var amount: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, label: String, name: String, region: String, quantity: String, amount: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.region = region
            self.quantity = quantity
            self.amount = amount
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageAgreementView(_ item: LanguageAgreement) -> LanguageAgreementView {
        return LanguageAgreementView(
            code: item.code,
            label: item.label,
            name: item.name,
            region: item.region,
            quantity: String(item.quantity),
            amount: String(format: "%.2f", item.amount),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageAgreementViews(_ items: [LanguageAgreement]) -> [LanguageAgreementView] {
        var views: [LanguageAgreementView] = []
        for item in items {
            views.append(toLanguageAgreementView(item))
        }
        return views
    }

    static func sumLanguageAgreementView(_ view: LanguageAgreementView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedQuantity) + parsedAmount + Double(parsedWindowDays)
    }
}
