import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory review.
    final class InventoryReviewView {
        var codeText: String
        var nameText: String
        var channelText: String
        var batchSizeText: String
        var attemptsText: String
        var timezoneText: String
        var currency: String
        var statusLabel: String

        init(codeText: String, nameText: String, channelText: String, batchSizeText: String, attemptsText: String, timezoneText: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.channelText = channelText
            self.batchSizeText = batchSizeText
            self.attemptsText = attemptsText
            self.timezoneText = timezoneText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryReviewView(_ item: InventoryReview) -> InventoryReviewView {
        return InventoryReviewView(
            codeText: item.code,
            nameText: item.name,
            channelText: item.channel,
            batchSizeText: String(item.batchSize),
            attemptsText: String(item.attempts),
            timezoneText: item.timezone,
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryReviewViews(_ items: [InventoryReview]) -> [InventoryReviewView] {
        var views: [InventoryReviewView] = []
        for item in items {
            views.append(toInventoryReviewView(item))
        }
        return views
    }

    static func sumInventoryReviewView(_ view: InventoryReviewView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedAttempts)
    }
}
