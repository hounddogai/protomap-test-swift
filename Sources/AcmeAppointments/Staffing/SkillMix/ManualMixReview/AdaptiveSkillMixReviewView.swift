import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive skill mix review.
    final class AdaptiveSkillMixReviewView {
        var code: String
        var label: String
        var diagnosisCode: String
        var description: String
        var pinned: String
        var timezone: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, description: String, pinned: String, timezone: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.description = description
            self.pinned = pinned
            self.timezone = timezone
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveSkillMixReviewView(_ item: AdaptiveSkillMixReview) -> AdaptiveSkillMixReviewView {
        return AdaptiveSkillMixReviewView(
            code: item.code,
            label: item.label,
            diagnosisCode: item.diagnosisCode,
            description: item.description,
            pinned: "\(item.pinned)",
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveSkillMixReviewViews(_ items: [AdaptiveSkillMixReview]) -> [AdaptiveSkillMixReviewView] {
        var views: [AdaptiveSkillMixReviewView] = []
        for item in items {
            views.append(toAdaptiveSkillMixReviewView(item))
        }
        return views
    }

    static func sumAdaptiveSkillMixReviewView(_ view: AdaptiveSkillMixReviewView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
