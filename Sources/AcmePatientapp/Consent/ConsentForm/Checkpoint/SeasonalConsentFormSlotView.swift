import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a seasonal consent form slot.
    final class SeasonalConsentFormSlotView {
        var codeText: String
        var label: String
        var currency: String
        var visibleText: String
        var maximumText: String
        var discount: String
        var contactEmail: String
        var rate: String
        var statusLabel: String

        init(codeText: String, label: String, currency: String, visibleText: String, maximumText: String, discount: String, contactEmail: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.currency = currency
            self.visibleText = visibleText
            self.maximumText = maximumText
            self.discount = discount
            self.contactEmail = contactEmail
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalConsentFormSlotView(_ item: SeasonalConsentFormSlot) -> SeasonalConsentFormSlotView {
        return SeasonalConsentFormSlotView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            currency: item.currency,
            visibleText: "\(item.visible)",
            maximumText: String(format: "%.2f", item.maximum),
            discount: String(format: "%.2f", item.discount),
            contactEmail: item.contactEmail,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalConsentFormSlotViews(_ items: [SeasonalConsentFormSlot]) -> [SeasonalConsentFormSlotView] {
        var views: [SeasonalConsentFormSlotView] = []
        for item in items {
            views.append(toSeasonalConsentFormSlotView(item))
        }
        return views
    }

    static func sumSeasonalConsentFormSlotView(_ view: SeasonalConsentFormSlotView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedMaximum + parsedDiscount + parsedRate
    }
}
