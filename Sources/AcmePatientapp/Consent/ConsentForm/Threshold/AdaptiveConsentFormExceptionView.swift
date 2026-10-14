import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive consent form exception.
    final class AdaptiveConsentFormExceptionView {
        var code: String
        var title: String
        var copay: String
        var payer: String
        var category: String
        var statusLabel: String

        init(code: String, title: String, copay: String, payer: String, category: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.copay = copay
            self.payer = payer
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveConsentFormExceptionView(_ item: AdaptiveConsentFormException) -> AdaptiveConsentFormExceptionView {
        return AdaptiveConsentFormExceptionView(
            code: item.code,
            title: item.title,
            copay: String(format: "%.2f", item.copay),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveConsentFormExceptionViews(_ items: [AdaptiveConsentFormException]) -> [AdaptiveConsentFormExceptionView] {
        var views: [AdaptiveConsentFormExceptionView] = []
        for item in items {
            views.append(toAdaptiveConsentFormExceptionView(item))
        }
        return views
    }

    static func sumAdaptiveConsentFormExceptionView(_ view: AdaptiveConsentFormExceptionView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
