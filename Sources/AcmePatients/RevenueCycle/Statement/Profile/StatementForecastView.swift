import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement forecast.
    final class StatementForecastView {
        var code: String
        var titleText: String
        var retries: String
        var amountText: String
        var margin: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, titleText: String, retries: String, amountText: String, margin: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.retries = retries
            self.amountText = amountText
            self.margin = margin
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toStatementForecastView(_ item: StatementForecast) -> StatementForecastView {
        return StatementForecastView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            retries: String(item.retries),
            amountText: String(format: "%.2f", item.amount),
            margin: String(format: "%.2f", item.margin),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementForecastViews(_ items: [StatementForecast]) -> [StatementForecastView] {
        var views: [StatementForecastView] = []
        for item in items {
            views.append(toStatementForecastView(item))
        }
        return views
    }

    static func sumStatementForecastView(_ view: StatementForecastView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedRetries) + parsedAmount + parsedMargin
    }
}
