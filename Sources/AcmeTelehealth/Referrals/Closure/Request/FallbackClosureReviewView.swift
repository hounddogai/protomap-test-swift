import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback closure review.
    final class FallbackClosureReviewView {
        var code: String
        var label: String
        var clinicianIDText: String
        var weight: String
        var payer: String
        var limit: String
        var budget: String
        var unitText: String
        var statusLabel: String

        init(code: String, label: String, clinicianIDText: String, weight: String, payer: String, limit: String, budget: String, unitText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.clinicianIDText = clinicianIDText
            self.weight = weight
            self.payer = payer
            self.limit = limit
            self.budget = budget
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackClosureReviewView(_ item: FallbackClosureReview) -> FallbackClosureReviewView {
        return FallbackClosureReviewView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            clinicianIDText: item.clinicianID,
            weight: String(format: "%.2f", item.weight),
            payer: item.payer,
            limit: String(item.limit),
            budget: String(format: "%.2f", item.budget),
            unitText: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackClosureReviewViews(_ items: [FallbackClosureReview]) -> [FallbackClosureReviewView] {
        var views: [FallbackClosureReviewView] = []
        for item in items {
            views.append(toFallbackClosureReviewView(item))
        }
        return views
    }

    static func sumFallbackClosureReviewView(_ view: FallbackClosureReviewView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedWeight + Double(parsedLimit) + parsedBudget
    }
}
