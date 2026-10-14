import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional substitution review.
    final class RegionalSubstitutionReviewView {
        var codeText: String
        var name: String
        var country: String
        var floorValueText: String
        var patientRefText: String
        var score: String
        var payer: String
        var rate: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, name: String, country: String, floorValueText: String, patientRefText: String, score: String, payer: String, rate: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.country = country
            self.floorValueText = floorValueText
            self.patientRefText = patientRefText
            self.score = score
            self.payer = payer
            self.rate = rate
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSubstitutionReviewView(_ item: RegionalSubstitutionReview) -> RegionalSubstitutionReviewView {
        return RegionalSubstitutionReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 120),
            country: item.country,
            floorValueText: String(format: "%.2f", item.floorValue),
            patientRefText: item.patientRef,
            score: String(format: "%.2f", item.score),
            payer: item.payer,
            rate: String(format: "%.2f", item.rate),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSubstitutionReviewViews(_ items: [RegionalSubstitutionReview]) -> [RegionalSubstitutionReviewView] {
        var views: [RegionalSubstitutionReviewView] = []
        for item in items {
            views.append(toRegionalSubstitutionReviewView(item))
        }
        return views
    }

    static func sumRegionalSubstitutionReviewView(_ view: RegionalSubstitutionReviewView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedFloorValue + parsedScore + parsedRate
    }
}
