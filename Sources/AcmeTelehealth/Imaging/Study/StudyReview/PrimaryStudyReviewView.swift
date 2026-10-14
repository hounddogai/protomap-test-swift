import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary study review.
    final class PrimaryStudyReviewView {
        var code: String
        var label: String
        var source: String
        var startsAt: String
        var archived: String
        var attemptsText: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, source: String, startsAt: String, archived: String, attemptsText: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.source = source
            self.startsAt = startsAt
            self.archived = archived
            self.attemptsText = attemptsText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryStudyReviewView(_ item: PrimaryStudyReview) -> PrimaryStudyReviewView {
        return PrimaryStudyReviewView(
            code: item.code,
            label: item.label,
            source: item.source,
            startsAt: String(item.startsAt),
            archived: "\(item.archived)",
            attemptsText: String(item.attempts),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryStudyReviewViews(_ items: [PrimaryStudyReview]) -> [PrimaryStudyReviewView] {
        var views: [PrimaryStudyReviewView] = []
        for item in items {
            views.append(toPrimaryStudyReviewView(item))
        }
        return views
    }

    static func sumPrimaryStudyReviewView(_ view: PrimaryStudyReviewView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedAttempts)
    }
}
