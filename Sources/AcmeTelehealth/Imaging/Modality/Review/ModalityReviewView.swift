import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality review.
    final class ModalityReviewView {
        var code: String
        var title: String
        var sequence: String
        var channelText: String
        var amountText: String
        var rate: String
        var statusLabel: String

        init(code: String, title: String, sequence: String, channelText: String, amountText: String, rate: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.channelText = channelText
            self.amountText = amountText
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toModalityReviewView(_ item: ModalityReview) -> ModalityReviewView {
        return ModalityReviewView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            sequence: String(item.sequence),
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            amountText: String(format: "%.2f", item.amount),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityReviewViews(_ items: [ModalityReview]) -> [ModalityReviewView] {
        var views: [ModalityReviewView] = []
        for item in items {
            views.append(toModalityReviewView(item))
        }
        return views
    }

    static func sumModalityReviewView(_ view: ModalityReviewView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedSequence) + parsedAmount + parsedRate
    }
}
