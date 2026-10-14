import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a capped isolation review.
    final class CappedIsolationReviewView {
        var code: String
        var name: String
        var pinnedText: String
        var ownerID: String
        var scoreText: String
        var statusLabel: String

        init(code: String, name: String, pinnedText: String, ownerID: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinnedText = pinnedText
            self.ownerID = ownerID
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedIsolationReviewView(_ item: CappedIsolationReview) -> CappedIsolationReviewView {
        return CappedIsolationReviewView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            pinnedText: "\(item.pinned)",
            ownerID: item.ownerID,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedIsolationReviewViews(_ items: [CappedIsolationReview]) -> [CappedIsolationReviewView] {
        var views: [CappedIsolationReviewView] = []
        for item in items {
            views.append(toCappedIsolationReviewView(item))
        }
        return views
    }

    static func sumCappedIsolationReviewView(_ view: CappedIsolationReviewView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
