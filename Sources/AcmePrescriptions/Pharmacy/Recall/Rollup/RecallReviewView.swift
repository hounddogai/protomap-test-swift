import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall review.
    final class RecallReviewView {
        var codeText: String
        var name: String
        var updatedAt: String
        var endsAt: String
        var source: String
        var notesText: String
        var statusLabel: String

        init(codeText: String, name: String, updatedAt: String, endsAt: String, source: String, notesText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.updatedAt = updatedAt
            self.endsAt = endsAt
            self.source = source
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toRecallReviewView(_ item: RecallReview) -> RecallReviewView {
        return RecallReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            updatedAt: String(item.updatedAt),
            endsAt: String(item.endsAt),
            source: item.source,
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallReviewViews(_ items: [RecallReview]) -> [RecallReviewView] {
        var views: [RecallReviewView] = []
        for item in items {
            views.append(toRecallReviewView(item))
        }
        return views
    }

    static func sumRecallReviewView(_ view: RecallReviewView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedEndsAt)
    }
}
