import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial cycle.
    final class DenialCycleView {
        var codeText: String
        var name: String
        var budgetText: String
        var reviewerText: String
        var ceilingText: String
        var sequence: String
        var wardText: String
        var amount: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(codeText: String, name: String, budgetText: String, reviewerText: String, ceilingText: String, sequence: String, wardText: String, amount: String, diagnosisCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.budgetText = budgetText
            self.reviewerText = reviewerText
            self.ceilingText = ceilingText
            self.sequence = sequence
            self.wardText = wardText
            self.amount = amount
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toDenialCycleView(_ item: DenialCycle) -> DenialCycleView {
        return DenialCycleView(
            codeText: item.code,
            name: item.name,
            budgetText: String(format: "%.2f", item.budget),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            ceilingText: String(format: "%.2f", item.ceiling),
            sequence: String(item.sequence),
            wardText: item.ward,
            amount: String(format: "%.2f", item.amount),
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialCycleViews(_ items: [DenialCycle]) -> [DenialCycleView] {
        var views: [DenialCycleView] = []
        for item in items {
            views.append(toDenialCycleView(item))
        }
        return views
    }

    static func sumDenialCycleView(_ view: DenialCycleView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedBudget + parsedCeiling + Double(parsedSequence)
    }
}
