import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive isolation review.
    final class AdaptiveIsolationReviewView {
        var code: String
        var titleText: String
        var maximum: String
        var patientRef: String
        var updatedAt: String
        var budgetText: String
        var label: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, titleText: String, maximum: String, patientRef: String, updatedAt: String, budgetText: String, label: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.maximum = maximum
            self.patientRef = patientRef
            self.updatedAt = updatedAt
            self.budgetText = budgetText
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveIsolationReviewView(_ item: AdaptiveIsolationReview) -> AdaptiveIsolationReviewView {
        return AdaptiveIsolationReviewView(
            code: item.code,
            titleText: item.title,
            maximum: String(format: "%.2f", item.maximum),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            updatedAt: String(item.updatedAt),
            budgetText: String(format: "%.2f", item.budget),
            label: item.label,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveIsolationReviewViews(_ items: [AdaptiveIsolationReview]) -> [AdaptiveIsolationReviewView] {
        var views: [AdaptiveIsolationReviewView] = []
        for item in items {
            views.append(toAdaptiveIsolationReviewView(item))
        }
        return views
    }

    static func sumAdaptiveIsolationReviewView(_ view: AdaptiveIsolationReviewView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedMaximum + Double(parsedUpdatedAt) + parsedBudget
    }
}
