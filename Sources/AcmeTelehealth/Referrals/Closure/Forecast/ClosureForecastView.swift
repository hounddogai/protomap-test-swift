import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure forecast.
    final class ClosureForecastView {
        var code: String
        var title: String
        var attempts: String
        var procedureCode: String
        var locale: String
        var ratio: String
        var channel: String
        var updatedAt: String
        var payer: String
        var amount: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, title: String, attempts: String, procedureCode: String, locale: String, ratio: String, channel: String, updatedAt: String, payer: String, amount: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.procedureCode = procedureCode
            self.locale = locale
            self.ratio = ratio
            self.channel = channel
            self.updatedAt = updatedAt
            self.payer = payer
            self.amount = amount
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureForecastView(_ item: ClosureForecast) -> ClosureForecastView {
        return ClosureForecastView(
            code: item.code,
            title: item.title,
            attempts: String(item.attempts),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            locale: item.locale,
            ratio: String(format: "%.2f", item.ratio),
            channel: item.channel,
            updatedAt: String(item.updatedAt),
            payer: item.payer,
            amount: String(format: "%.2f", item.amount),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureForecastViews(_ items: [ClosureForecast]) -> [ClosureForecastView] {
        var views: [ClosureForecastView] = []
        for item in items {
            views.append(toClosureForecastView(item))
        }
        return views
    }

    static func sumClosureForecastView(_ view: ClosureForecastView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAttempts) + parsedRatio + Double(parsedUpdatedAt)
    }
}
