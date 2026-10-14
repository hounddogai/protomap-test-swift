import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default proxy claim.
    final class DefaultProxyClaimView {
        var code: String
        var name: String
        var titleText: String
        var retriesText: String
        var archived: String
        var currencyText: String
        var dosageMg: String
        var graceDays: String
        var amount: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, name: String, titleText: String, retriesText: String, archived: String, currencyText: String, dosageMg: String, graceDays: String, amount: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.titleText = titleText
            self.retriesText = retriesText
            self.archived = archived
            self.currencyText = currencyText
            self.dosageMg = dosageMg
            self.graceDays = graceDays
            self.amount = amount
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultProxyClaimView(_ item: DefaultProxyClaim) -> DefaultProxyClaimView {
        return DefaultProxyClaimView(
            code: item.code,
            name: item.name,
            titleText: item.title,
            retriesText: String(item.retries),
            archived: "\(item.archived)",
            currencyText: item.currency,
            dosageMg: String(format: "%.2f", item.dosageMg),
            graceDays: String(item.graceDays),
            amount: String(format: "%.2f", item.amount),
            encounterIDText: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultProxyClaimViews(_ items: [DefaultProxyClaim]) -> [DefaultProxyClaimView] {
        var views: [DefaultProxyClaimView] = []
        for item in items {
            views.append(toDefaultProxyClaimView(item))
        }
        return views
    }

    static func sumDefaultProxyClaimView(_ view: DefaultProxyClaimView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedRetries) + parsedDosageMg + Double(parsedGraceDays)
    }
}
