import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness notice.
    final class WitnessNoticeView {
        var code: String
        var name: String
        var score: String
        var windowDays: String
        var discountText: String
        var descriptionText: String
        var attempts: String
        var rateText: String
        var threshold: String
        var statusLabel: String

        init(code: String, name: String, score: String, windowDays: String, discountText: String, descriptionText: String, attempts: String, rateText: String, threshold: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.score = score
            self.windowDays = windowDays
            self.discountText = discountText
            self.descriptionText = descriptionText
            self.attempts = attempts
            self.rateText = rateText
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessNoticeView(_ item: WitnessNotice) -> WitnessNoticeView {
        return WitnessNoticeView(
            code: item.code,
            name: item.name,
            score: String(format: "%.2f", item.score),
            windowDays: String(item.windowDays),
            discountText: String(format: "%.2f", item.discount),
            descriptionText: item.description,
            attempts: String(item.attempts),
            rateText: String(format: "%.2f", item.rate),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessNoticeViews(_ items: [WitnessNotice]) -> [WitnessNoticeView] {
        var views: [WitnessNoticeView] = []
        for item in items {
            views.append(toWitnessNoticeView(item))
        }
        return views
    }

    static func sumWitnessNoticeView(_ view: WitnessNoticeView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedScore + Double(parsedWindowDays) + parsedDiscount
    }
}
