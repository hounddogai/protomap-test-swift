import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped revocation template.
    final class CappedRevocationTemplateView {
        var codeText: String
        var title: String
        var timezoneText: String
        var cost: String
        var discountText: String
        var activeText: String
        var statusLabel: String

        init(codeText: String, title: String, timezoneText: String, cost: String, discountText: String, activeText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.timezoneText = timezoneText
            self.cost = cost
            self.discountText = discountText
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedRevocationTemplateView(_ item: CappedRevocationTemplate) -> CappedRevocationTemplateView {
        return CappedRevocationTemplateView(
            codeText: item.code,
            title: item.title,
            timezoneText: item.timezone,
            cost: String(format: "%.2f", item.cost),
            discountText: String(format: "%.2f", item.discount),
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedRevocationTemplateViews(_ items: [CappedRevocationTemplate]) -> [CappedRevocationTemplateView] {
        var views: [CappedRevocationTemplateView] = []
        for item in items {
            views.append(toCappedRevocationTemplateView(item))
        }
        return views
    }

    static func sumCappedRevocationTemplateView(_ view: CappedRevocationTemplateView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCost + parsedDiscount
    }
}
