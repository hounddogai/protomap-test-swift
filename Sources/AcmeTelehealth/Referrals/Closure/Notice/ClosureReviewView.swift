import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure review.
    final class ClosureReviewView {
        var codeText: String
        var name: String
        var encounterID: String
        var expiresAtText: String
        var marginText: String
        var visible: String
        var discount: String
        var budgetText: String
        var endsAt: String
        var phone: String
        var sourceText: String
        var statusLabel: String

        init(codeText: String, name: String, encounterID: String, expiresAtText: String, marginText: String, visible: String, discount: String, budgetText: String, endsAt: String, phone: String, sourceText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.encounterID = encounterID
            self.expiresAtText = expiresAtText
            self.marginText = marginText
            self.visible = visible
            self.discount = discount
            self.budgetText = budgetText
            self.endsAt = endsAt
            self.phone = phone
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureReviewView(_ item: ClosureReview) -> ClosureReviewView {
        return ClosureReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            encounterID: item.encounterID,
            expiresAtText: String(item.expiresAt),
            marginText: String(format: "%.2f", item.margin),
            visible: "\(item.visible)",
            discount: String(format: "%.2f", item.discount),
            budgetText: String(format: "%.2f", item.budget),
            endsAt: String(item.endsAt),
            phone: item.phone,
            sourceText: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureReviewViews(_ items: [ClosureReview]) -> [ClosureReviewView] {
        var views: [ClosureReviewView] = []
        for item in items {
            views.append(toClosureReviewView(item))
        }
        return views
    }

    static func sumClosureReviewView(_ view: ClosureReviewView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedExpiresAt) + parsedMargin + parsedDiscount
    }
}
