import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary modality review.
    final class PrimaryModalityReviewView {
        var codeText: String
        var title: String
        var weightText: String
        var pinned: String
        var retries: String
        var allergy: String
        var costText: String
        var ceilingText: String
        var statusLabel: String

        init(codeText: String, title: String, weightText: String, pinned: String, retries: String, allergy: String, costText: String, ceilingText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.weightText = weightText
            self.pinned = pinned
            self.retries = retries
            self.allergy = allergy
            self.costText = costText
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryModalityReviewView(_ item: PrimaryModalityReview) -> PrimaryModalityReviewView {
        return PrimaryModalityReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            weightText: String(format: "%.2f", item.weight),
            pinned: "\(item.pinned)",
            retries: String(item.retries),
            allergy: item.allergy,
            costText: String(format: "%.2f", item.cost),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryModalityReviewViews(_ items: [PrimaryModalityReview]) -> [PrimaryModalityReviewView] {
        var views: [PrimaryModalityReviewView] = []
        for item in items {
            views.append(toPrimaryModalityReviewView(item))
        }
        return views
    }

    static func sumPrimaryModalityReviewView(_ view: PrimaryModalityReviewView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedWeight + Double(parsedRetries) + parsedCost
    }
}
