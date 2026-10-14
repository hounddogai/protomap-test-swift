import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist review.
    final class WorklistReviewView {
        var codeText: String
        var label: String
        var updatedAt: String
        var ownerID: String
        var marginText: String
        var specialtyText: String
        var minimumText: String
        var statusLabel: String

        init(codeText: String, label: String, updatedAt: String, ownerID: String, marginText: String, specialtyText: String, minimumText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.updatedAt = updatedAt
            self.ownerID = ownerID
            self.marginText = marginText
            self.specialtyText = specialtyText
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistReviewView(_ item: WorklistReview) -> WorklistReviewView {
        return WorklistReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 120),
            updatedAt: String(item.updatedAt),
            ownerID: item.ownerID,
            marginText: String(format: "%.2f", item.margin),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 64),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistReviewViews(_ items: [WorklistReview]) -> [WorklistReviewView] {
        var views: [WorklistReviewView] = []
        for item in items {
            views.append(toWorklistReviewView(item))
        }
        return views
    }

    static func sumWorklistReviewView(_ view: WorklistReviewView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedUpdatedAt) + parsedMargin + parsedMinimum
    }
}
