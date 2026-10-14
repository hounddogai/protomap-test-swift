import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive dispense review.
    final class AdaptiveDispenseReviewView {
        var code: String
        var label: String
        var encounterID: String
        var payer: String
        var description: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, payer: String, description: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.payer = payer
            self.description = description
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveDispenseReviewView(_ item: AdaptiveDispenseReview) -> AdaptiveDispenseReviewView {
        return AdaptiveDispenseReviewView(
            code: item.code,
            label: item.label,
            encounterID: item.encounterID,
            payer: item.payer,
            description: item.description,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveDispenseReviewViews(_ items: [AdaptiveDispenseReview]) -> [AdaptiveDispenseReviewView] {
        var views: [AdaptiveDispenseReviewView] = []
        for item in items {
            views.append(toAdaptiveDispenseReviewView(item))
        }
        return views
    }

    static func sumAdaptiveDispenseReviewView(_ view: AdaptiveDispenseReviewView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
