import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility agreement.
    final class EligibilityAgreementView {
        var code: String
        var titleText: String
        var scoreText: String
        var budgetText: String
        var rate: String
        var approved: String
        var floorValue: String
        var statusLabel: String

        init(code: String, titleText: String, scoreText: String, budgetText: String, rate: String, approved: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.scoreText = scoreText
            self.budgetText = budgetText
            self.rate = rate
            self.approved = approved
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityAgreementView(_ item: EligibilityAgreement) -> EligibilityAgreementView {
        return EligibilityAgreementView(
            code: item.code,
            titleText: item.title,
            scoreText: String(format: "%.2f", item.score),
            budgetText: String(format: "%.2f", item.budget),
            rate: String(format: "%.2f", item.rate),
            approved: "\(item.approved)",
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityAgreementViews(_ items: [EligibilityAgreement]) -> [EligibilityAgreementView] {
        var views: [EligibilityAgreementView] = []
        for item in items {
            views.append(toEligibilityAgreementView(item))
        }
        return views
    }

    static func sumEligibilityAgreementView(_ view: EligibilityAgreementView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedScore + parsedBudget + parsedRate
    }
}
