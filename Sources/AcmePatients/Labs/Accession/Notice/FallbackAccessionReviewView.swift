import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback accession review.
    final class FallbackAccessionReviewView {
        var code: String
        var labelText: String
        var pinned: String
        var discountText: String
        var threshold: String
        var statusLabel: String

        init(code: String, labelText: String, pinned: String, discountText: String, threshold: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.pinned = pinned
            self.discountText = discountText
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAccessionReviewView(_ item: FallbackAccessionReview) -> FallbackAccessionReviewView {
        return FallbackAccessionReviewView(
            code: item.code,
            labelText: item.label,
            pinned: "\(item.pinned)",
            discountText: String(format: "%.2f", item.discount),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAccessionReviewViews(_ items: [FallbackAccessionReview]) -> [FallbackAccessionReviewView] {
        var views: [FallbackAccessionReviewView] = []
        for item in items {
            views.append(toFallbackAccessionReviewView(item))
        }
        return views
    }

    static func sumFallbackAccessionReviewView(_ view: FallbackAccessionReviewView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedDiscount + parsedThreshold
    }
}
