import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered claim review.
    final class TieredClaimReviewView {
        var codeText: String
        var label: String
        var discount: String
        var visibleText: String
        var unit: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, label: String, discount: String, visibleText: String, unit: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.discount = discount
            self.visibleText = visibleText
            self.unit = unit
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toTieredClaimReviewView(_ item: TieredClaimReview) -> TieredClaimReviewView {
        return TieredClaimReviewView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            discount: String(format: "%.2f", item.discount),
            visibleText: "\(item.visible)",
            unit: item.unit,
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredClaimReviewViews(_ items: [TieredClaimReview]) -> [TieredClaimReviewView] {
        var views: [TieredClaimReviewView] = []
        for item in items {
            views.append(toTieredClaimReviewView(item))
        }
        return views
    }

    static func sumTieredClaimReviewView(_ view: TieredClaimReviewView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
