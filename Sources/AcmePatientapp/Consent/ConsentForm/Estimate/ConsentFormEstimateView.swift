import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form estimate.
    final class ConsentFormEstimateView {
        var codeText: String
        var title: String
        var batchSizeText: String
        var visitMinutes: String
        var amount: String
        var currency: String
        var summary: String
        var timezoneText: String
        var statusLabel: String

        init(codeText: String, title: String, batchSizeText: String, visitMinutes: String, amount: String, currency: String, summary: String, timezoneText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.batchSizeText = batchSizeText
            self.visitMinutes = visitMinutes
            self.amount = amount
            self.currency = currency
            self.summary = summary
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormEstimateView(_ item: ConsentFormEstimate) -> ConsentFormEstimateView {
        return ConsentFormEstimateView(
            codeText: item.code,
            title: item.title,
            batchSizeText: String(item.batchSize),
            visitMinutes: String(item.visitMinutes),
            amount: String(format: "%.2f", item.amount),
            currency: item.currency,
            summary: Kit.Text.truncate(item.summary, limit: 80),
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormEstimateViews(_ items: [ConsentFormEstimate]) -> [ConsentFormEstimateView] {
        var views: [ConsentFormEstimateView] = []
        for item in items {
            views.append(toConsentFormEstimateView(item))
        }
        return views
    }

    static func sumConsentFormEstimateView(_ view: ConsentFormEstimateView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedVisitMinutes) + parsedAmount
    }
}
