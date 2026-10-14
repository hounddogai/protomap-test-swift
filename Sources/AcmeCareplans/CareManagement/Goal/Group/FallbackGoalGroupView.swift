import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback goal group.
    final class FallbackGoalGroupView {
        var code: String
        var title: String
        var budgetText: String
        var endsAt: String
        var procedureCodeText: String
        var threshold: String
        var reviewer: String
        var minimum: String
        var quantityText: String
        var patientRef: String
        var externalRef: String
        var statusLabel: String

        init(code: String, title: String, budgetText: String, endsAt: String, procedureCodeText: String, threshold: String, reviewer: String, minimum: String, quantityText: String, patientRef: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.budgetText = budgetText
            self.endsAt = endsAt
            self.procedureCodeText = procedureCodeText
            self.threshold = threshold
            self.reviewer = reviewer
            self.minimum = minimum
            self.quantityText = quantityText
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackGoalGroupView(_ item: FallbackGoalGroup) -> FallbackGoalGroupView {
        return FallbackGoalGroupView(
            code: item.code,
            title: item.title,
            budgetText: String(format: "%.2f", item.budget),
            endsAt: String(item.endsAt),
            procedureCodeText: item.procedureCode,
            threshold: String(format: "%.2f", item.threshold),
            reviewer: item.reviewer,
            minimum: String(format: "%.2f", item.minimum),
            quantityText: String(item.quantity),
            patientRef: item.patientRef,
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackGoalGroupViews(_ items: [FallbackGoalGroup]) -> [FallbackGoalGroupView] {
        var views: [FallbackGoalGroupView] = []
        for item in items {
            views.append(toFallbackGoalGroupView(item))
        }
        return views
    }

    static func sumFallbackGoalGroupView(_ view: FallbackGoalGroupView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedBudget + Double(parsedEndsAt) + parsedThreshold
    }
}
