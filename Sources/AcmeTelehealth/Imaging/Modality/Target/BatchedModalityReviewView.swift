import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a batched modality review.
    final class BatchedModalityReviewView {
        var code: String
        var nameText: String
        var ownerID: String
        var allergy: String
        var description: String
        var scoreText: String
        var statusLabel: String

        init(code: String, nameText: String, ownerID: String, allergy: String, description: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ownerID = ownerID
            self.allergy = allergy
            self.description = description
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedModalityReviewView(_ item: BatchedModalityReview) -> BatchedModalityReviewView {
        return BatchedModalityReviewView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            allergy: item.allergy,
            description: item.description,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedModalityReviewViews(_ items: [BatchedModalityReview]) -> [BatchedModalityReviewView] {
        var views: [BatchedModalityReviewView] = []
        for item in items {
            views.append(toBatchedModalityReviewView(item))
        }
        return views
    }

    static func sumBatchedModalityReviewView(_ view: BatchedModalityReviewView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
