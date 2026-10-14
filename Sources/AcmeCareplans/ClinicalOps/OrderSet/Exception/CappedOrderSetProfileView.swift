import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a capped order set profile.
    final class CappedOrderSetProfileView {
        var codeText: String
        var title: String
        var unit: String
        var graceDaysText: String
        var score: String
        var currencyText: String
        var rateText: String
        var timezoneText: String
        var retriesText: String
        var statusLabel: String

        init(codeText: String, title: String, unit: String, graceDaysText: String, score: String, currencyText: String, rateText: String, timezoneText: String, retriesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.unit = unit
            self.graceDaysText = graceDaysText
            self.score = score
            self.currencyText = currencyText
            self.rateText = rateText
            self.timezoneText = timezoneText
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedOrderSetProfileView(_ item: CappedOrderSetProfile) -> CappedOrderSetProfileView {
        return CappedOrderSetProfileView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            unit: item.unit,
            graceDaysText: String(item.graceDays),
            score: String(format: "%.2f", item.score),
            currencyText: Kit.Text.truncate(item.currency, limit: 40),
            rateText: String(format: "%.2f", item.rate),
            timezoneText: item.timezone,
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedOrderSetProfileViews(_ items: [CappedOrderSetProfile]) -> [CappedOrderSetProfileView] {
        var views: [CappedOrderSetProfileView] = []
        for item in items {
            views.append(toCappedOrderSetProfileView(item))
        }
        return views
    }

    static func sumCappedOrderSetProfileView(_ view: CappedOrderSetProfileView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedGraceDays) + parsedScore + parsedRate
    }
}
