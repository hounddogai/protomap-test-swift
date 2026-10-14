import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction review.
    final class InteractionReviewView {
        var code: String
        var label: String
        var titleText: String
        var retriesText: String
        var margin: String
        var costText: String
        var statusLabel: String

        init(code: String, label: String, titleText: String, retriesText: String, margin: String, costText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.titleText = titleText
            self.retriesText = retriesText
            self.margin = margin
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionReviewView(_ item: InteractionReview) -> InteractionReviewView {
        return InteractionReviewView(
            code: item.code,
            label: item.label,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            retriesText: String(item.retries),
            margin: String(format: "%.2f", item.margin),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionReviewViews(_ items: [InteractionReview]) -> [InteractionReviewView] {
        var views: [InteractionReviewView] = []
        for item in items {
            views.append(toInteractionReviewView(item))
        }
        return views
    }

    static func sumInteractionReviewView(_ view: InteractionReviewView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedRetries) + parsedMargin + parsedCost
    }
}
