import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive alert summary.
    final class AdaptiveAlertSummaryView {
        var code: String
        var titleText: String
        var procedureCodeText: String
        var locale: String
        var amount: String
        var statusLabel: String

        init(code: String, titleText: String, procedureCodeText: String, locale: String, amount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.procedureCodeText = procedureCodeText
            self.locale = locale
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAlertSummaryView(_ item: AdaptiveAlertSummary) -> AdaptiveAlertSummaryView {
        return AdaptiveAlertSummaryView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 120),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAlertSummaryViews(_ items: [AdaptiveAlertSummary]) -> [AdaptiveAlertSummaryView] {
        var views: [AdaptiveAlertSummaryView] = []
        for item in items {
            views.append(toAdaptiveAlertSummaryView(item))
        }
        return views
    }

    static func sumAdaptiveAlertSummaryView(_ view: AdaptiveAlertSummaryView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
