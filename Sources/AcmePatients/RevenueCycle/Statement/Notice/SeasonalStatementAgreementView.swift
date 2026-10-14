import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a seasonal statement agreement.
    final class SeasonalStatementAgreementView {
        var code: String
        var name: String
        var retriesText: String
        var currencyText: String
        var segmentText: String
        var priority: String
        var expiresAtText: String
        var timezone: String
        var ratioText: String
        var statusLabel: String

        init(code: String, name: String, retriesText: String, currencyText: String, segmentText: String, priority: String, expiresAtText: String, timezone: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.retriesText = retriesText
            self.currencyText = currencyText
            self.segmentText = segmentText
            self.priority = priority
            self.expiresAtText = expiresAtText
            self.timezone = timezone
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalStatementAgreementView(_ item: SeasonalStatementAgreement) -> SeasonalStatementAgreementView {
        return SeasonalStatementAgreementView(
            code: item.code,
            name: item.name,
            retriesText: String(item.retries),
            currencyText: item.currency,
            segmentText: item.segment,
            priority: String(item.priority),
            expiresAtText: String(item.expiresAt),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalStatementAgreementViews(_ items: [SeasonalStatementAgreement]) -> [SeasonalStatementAgreementView] {
        var views: [SeasonalStatementAgreementView] = []
        for item in items {
            views.append(toSeasonalStatementAgreementView(item))
        }
        return views
    }

    static func sumSeasonalStatementAgreementView(_ view: SeasonalStatementAgreementView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedRetries) + Double(parsedPriority) + Double(parsedExpiresAt)
    }
}
