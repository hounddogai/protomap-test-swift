import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeManualRecallVariancesForPlan(_ items: [ManualRecallVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveSubstitutionPlansFromVariance(_ items: [ManualRecallVariance]) -> [SubstitutionPlan] {
        var out: [SubstitutionPlan] = []
        for item in items {
            let derived = newSubstitutionPlan(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applySubstitutionPlan(_ item: SubstitutionPlan) -> String {
        return classifyFallbackRecallPolicy(item.projectedValue())
    }
}
