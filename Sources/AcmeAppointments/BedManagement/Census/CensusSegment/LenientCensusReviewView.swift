import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient census review.
    final class LenientCensusReviewView {
        var code: String
        var label: String
        var ceiling: String
        var retries: String
        var priority: String
        var countryText: String
        var windowDays: String
        var ownerID: String
        var rateText: String
        var statusLabel: String

        init(code: String, label: String, ceiling: String, retries: String, priority: String, countryText: String, windowDays: String, ownerID: String, rateText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.retries = retries
            self.priority = priority
            self.countryText = countryText
            self.windowDays = windowDays
            self.ownerID = ownerID
            self.rateText = rateText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCensusReviewView(_ item: LenientCensusReview) -> LenientCensusReviewView {
        return LenientCensusReviewView(
            code: item.code,
            label: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            retries: String(item.retries),
            priority: String(item.priority),
            countryText: item.country,
            windowDays: String(item.windowDays),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            rateText: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCensusReviewViews(_ items: [LenientCensusReview]) -> [LenientCensusReviewView] {
        var views: [LenientCensusReviewView] = []
        for item in items {
            views.append(toLenientCensusReviewView(item))
        }
        return views
    }

    static func sumLenientCensusReviewView(_ view: LenientCensusReviewView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedCeiling + Double(parsedRetries) + Double(parsedPriority)
    }
}
