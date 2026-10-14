import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense review.
    final class DispenseReviewView {
        var code: String
        var nameText: String
        var graceDaysText: String
        var channel: String
        var locale: String
        var weight: String
        var reviewer: String
        var refillsText: String
        var retriesText: String
        var threshold: String
        var versionText: String
        var statusLabel: String

        init(code: String, nameText: String, graceDaysText: String, channel: String, locale: String, weight: String, reviewer: String, refillsText: String, retriesText: String, threshold: String, versionText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.graceDaysText = graceDaysText
            self.channel = channel
            self.locale = locale
            self.weight = weight
            self.reviewer = reviewer
            self.refillsText = refillsText
            self.retriesText = retriesText
            self.threshold = threshold
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseReviewView(_ item: DispenseReview) -> DispenseReviewView {
        return DispenseReviewView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            graceDaysText: String(item.graceDays),
            channel: item.channel,
            locale: item.locale,
            weight: String(format: "%.2f", item.weight),
            reviewer: item.reviewer,
            refillsText: String(item.refills),
            retriesText: String(item.retries),
            threshold: String(format: "%.2f", item.threshold),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseReviewViews(_ items: [DispenseReview]) -> [DispenseReviewView] {
        var views: [DispenseReviewView] = []
        for item in items {
            views.append(toDispenseReviewView(item))
        }
        return views
    }

    static func sumDispenseReviewView(_ view: DispenseReviewView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedGraceDays) + parsedWeight + Double(parsedRefills)
    }
}
