import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment review.
    final class AssessmentReviewView {
        var code: String
        var title: String
        var description: String
        var ward: String
        var visibleText: String
        var segment: String
        var discountText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, title: String, description: String, ward: String, visibleText: String, segment: String, discountText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.ward = ward
            self.visibleText = visibleText
            self.segment = segment
            self.discountText = discountText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentReviewView(_ item: AssessmentReview) -> AssessmentReviewView {
        return AssessmentReviewView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            description: Kit.Text.truncate(item.description, limit: 80),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            visibleText: "\(item.visible)",
            segment: item.segment,
            discountText: String(format: "%.2f", item.discount),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentReviewViews(_ items: [AssessmentReview]) -> [AssessmentReviewView] {
        var views: [AssessmentReviewView] = []
        for item in items {
            views.append(toAssessmentReviewView(item))
        }
        return views
    }

    static func sumAssessmentReviewView(_ view: AssessmentReviewView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + Double(parsedCreatedAt)
    }
}
