import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive recall review.
    final class AdaptiveRecallReviewView {
        var code: String
        var title: String
        var batchSizeText: String
        var maximum: String
        var label: String
        var procedureCodeText: String
        var costText: String
        var patientRef: String
        var statusLabel: String

        init(code: String, title: String, batchSizeText: String, maximum: String, label: String, procedureCodeText: String, costText: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.batchSizeText = batchSizeText
            self.maximum = maximum
            self.label = label
            self.procedureCodeText = procedureCodeText
            self.costText = costText
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRecallReviewView(_ item: AdaptiveRecallReview) -> AdaptiveRecallReviewView {
        return AdaptiveRecallReviewView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            batchSizeText: String(item.batchSize),
            maximum: String(format: "%.2f", item.maximum),
            label: item.label,
            procedureCodeText: item.procedureCode,
            costText: String(format: "%.2f", item.cost),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRecallReviewViews(_ items: [AdaptiveRecallReview]) -> [AdaptiveRecallReviewView] {
        var views: [AdaptiveRecallReviewView] = []
        for item in items {
            views.append(toAdaptiveRecallReviewView(item))
        }
        return views
    }

    static func sumAdaptiveRecallReviewView(_ view: AdaptiveRecallReviewView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedBatchSize) + parsedMaximum + parsedCost
    }
}
