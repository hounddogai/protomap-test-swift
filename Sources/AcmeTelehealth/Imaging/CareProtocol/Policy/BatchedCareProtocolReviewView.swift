import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a batched care protocol review.
    final class BatchedCareProtocolReviewView {
        var codeText: String
        var title: String
        var startsAtText: String
        var timezone: String
        var graceDays: String
        var limitText: String
        var statusLabel: String

        init(codeText: String, title: String, startsAtText: String, timezone: String, graceDays: String, limitText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.startsAtText = startsAtText
            self.timezone = timezone
            self.graceDays = graceDays
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCareProtocolReviewView(_ item: BatchedCareProtocolReview) -> BatchedCareProtocolReviewView {
        return BatchedCareProtocolReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 80),
            startsAtText: String(item.startsAt),
            timezone: item.timezone,
            graceDays: String(item.graceDays),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCareProtocolReviewViews(_ items: [BatchedCareProtocolReview]) -> [BatchedCareProtocolReviewView] {
        var views: [BatchedCareProtocolReviewView] = []
        for item in items {
            views.append(toBatchedCareProtocolReviewView(item))
        }
        return views
    }

    static func sumBatchedCareProtocolReviewView(_ view: BatchedCareProtocolReviewView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedGraceDays) + Double(parsedLimit)
    }
}
