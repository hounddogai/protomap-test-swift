import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a seasonal formulary review.
    final class SeasonalFormularyReviewView {
        var code: String
        var titleText: String
        var nameText: String
        var retries: String
        var label: String
        var budget: String
        var bed: String
        var approved: String
        var versionText: String
        var sequence: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, titleText: String, nameText: String, retries: String, label: String, budget: String, bed: String, approved: String, versionText: String, sequence: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.nameText = nameText
            self.retries = retries
            self.label = label
            self.budget = budget
            self.bed = bed
            self.approved = approved
            self.versionText = versionText
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalFormularyReviewView(_ item: SeasonalFormularyReview) -> SeasonalFormularyReviewView {
        return SeasonalFormularyReviewView(
            code: item.code,
            titleText: item.title,
            nameText: item.name,
            retries: String(item.retries),
            label: item.label,
            budget: String(format: "%.2f", item.budget),
            bed: item.bed,
            approved: "\(item.approved)",
            versionText: String(item.version),
            sequence: String(item.sequence),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalFormularyReviewViews(_ items: [SeasonalFormularyReview]) -> [SeasonalFormularyReviewView] {
        var views: [SeasonalFormularyReviewView] = []
        for item in items {
            views.append(toSeasonalFormularyReviewView(item))
        }
        return views
    }

    static func sumSeasonalFormularyReviewView(_ view: SeasonalFormularyReviewView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedRetries) + parsedBudget + Double(parsedVersion)
    }
}
