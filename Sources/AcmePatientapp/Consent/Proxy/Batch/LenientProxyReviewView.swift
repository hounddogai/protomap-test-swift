import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient proxy review.
    final class LenientProxyReviewView {
        var code: String
        var label: String
        var source: String
        var approved: String
        var visible: String
        var quantity: String
        var timezone: String
        var category: String
        var weight: String
        var statusLabel: String

        init(code: String, label: String, source: String, approved: String, visible: String, quantity: String, timezone: String, category: String, weight: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.source = source
            self.approved = approved
            self.visible = visible
            self.quantity = quantity
            self.timezone = timezone
            self.category = category
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toLenientProxyReviewView(_ item: LenientProxyReview) -> LenientProxyReviewView {
        return LenientProxyReviewView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 64),
            source: item.source,
            approved: "\(item.approved)",
            visible: "\(item.visible)",
            quantity: String(item.quantity),
            timezone: item.timezone,
            category: item.category,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientProxyReviewViews(_ items: [LenientProxyReview]) -> [LenientProxyReviewView] {
        var views: [LenientProxyReviewView] = []
        for item in items {
            views.append(toLenientProxyReviewView(item))
        }
        return views
    }

    static func sumLenientProxyReviewView(_ view: LenientProxyReviewView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedQuantity) + parsedWeight
    }
}
