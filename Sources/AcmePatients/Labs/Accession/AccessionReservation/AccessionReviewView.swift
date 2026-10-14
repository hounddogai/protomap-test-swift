import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession review.
    final class AccessionReviewView {
        var codeText: String
        var name: String
        var locale: String
        var regionText: String
        var summary: String
        var budget: String
        var country: String
        var bed: String
        var statusLabel: String

        init(codeText: String, name: String, locale: String, regionText: String, summary: String, budget: String, country: String, bed: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.locale = locale
            self.regionText = regionText
            self.summary = summary
            self.budget = budget
            self.country = country
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionReviewView(_ item: AccessionReview) -> AccessionReviewView {
        return AccessionReviewView(
            codeText: item.code,
            name: item.name,
            locale: item.locale,
            regionText: item.region,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            budget: String(format: "%.2f", item.budget),
            country: item.country,
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionReviewViews(_ items: [AccessionReview]) -> [AccessionReviewView] {
        var views: [AccessionReviewView] = []
        for item in items {
            views.append(toAccessionReviewView(item))
        }
        return views
    }

    static func sumAccessionReviewView(_ view: AccessionReviewView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
