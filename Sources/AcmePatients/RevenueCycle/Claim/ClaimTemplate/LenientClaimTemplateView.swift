import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient claim template.
    final class LenientClaimTemplateView {
        var codeText: String
        var name: String
        var locale: String
        var region: String
        var summary: String
        var amount: String
        var statusLabel: String

        init(codeText: String, name: String, locale: String, region: String, summary: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.locale = locale
            self.region = region
            self.summary = summary
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toLenientClaimTemplateView(_ item: LenientClaimTemplate) -> LenientClaimTemplateView {
        return LenientClaimTemplateView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            locale: item.locale,
            region: Kit.Text.truncate(item.region, limit: 64),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientClaimTemplateViews(_ items: [LenientClaimTemplate]) -> [LenientClaimTemplateView] {
        var views: [LenientClaimTemplateView] = []
        for item in items {
            views.append(toLenientClaimTemplateView(item))
        }
        return views
    }

    static func sumLenientClaimTemplateView(_ view: LenientClaimTemplateView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
