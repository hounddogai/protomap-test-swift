import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a default acuity plan threshold.
    final class DefaultAcuityPlanThresholdView {
        var code: String
        var label: String
        var ownerIDText: String
        var budget: String
        var thresholdText: String
        var phoneText: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, ownerIDText: String, budget: String, thresholdText: String, phoneText: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerIDText = ownerIDText
            self.budget = budget
            self.thresholdText = thresholdText
            self.phoneText = phoneText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultAcuityPlanThresholdView(_ item: DefaultAcuityPlanThreshold) -> DefaultAcuityPlanThresholdView {
        return DefaultAcuityPlanThresholdView(
            code: item.code,
            label: item.label,
            ownerIDText: item.ownerID,
            budget: String(format: "%.2f", item.budget),
            thresholdText: String(format: "%.2f", item.threshold),
            phoneText: item.phone,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultAcuityPlanThresholdViews(_ items: [DefaultAcuityPlanThreshold]) -> [DefaultAcuityPlanThresholdView] {
        var views: [DefaultAcuityPlanThresholdView] = []
        for item in items {
            views.append(toDefaultAcuityPlanThresholdView(item))
        }
        return views
    }

    static func sumDefaultAcuityPlanThresholdView(_ view: DefaultAcuityPlanThresholdView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedBudget + parsedThreshold + parsedScore
    }
}
