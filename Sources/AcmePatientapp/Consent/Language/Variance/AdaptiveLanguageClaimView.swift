import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive language claim.
    final class AdaptiveLanguageClaimView {
        var codeText: String
        var label: String
        var endsAt: String
        var discountText: String
        var region: String
        var statusLabel: String

        init(codeText: String, label: String, endsAt: String, discountText: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.endsAt = endsAt
            self.discountText = discountText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveLanguageClaimView(_ item: AdaptiveLanguageClaim) -> AdaptiveLanguageClaimView {
        return AdaptiveLanguageClaimView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            endsAt: String(item.endsAt),
            discountText: String(format: "%.2f", item.discount),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveLanguageClaimViews(_ items: [AdaptiveLanguageClaim]) -> [AdaptiveLanguageClaimView] {
        var views: [AdaptiveLanguageClaimView] = []
        for item in items {
            views.append(toAdaptiveLanguageClaimView(item))
        }
        return views
    }

    static func sumAdaptiveLanguageClaimView(_ view: AdaptiveLanguageClaimView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedEndsAt) + parsedDiscount
    }
}
