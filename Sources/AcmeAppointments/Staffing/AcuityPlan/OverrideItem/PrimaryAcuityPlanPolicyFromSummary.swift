import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeGlobalFloatPoolSummariesForPolicy(_ items: [GlobalFloatPoolSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func derivePrimaryAcuityPlanPoliciesFromSummary(_ items: [GlobalFloatPoolSummary]) -> [PrimaryAcuityPlanPolicy] {
        var out: [PrimaryAcuityPlanPolicy] = []
        for item in items {
            let derived = newPrimaryAcuityPlanPolicy(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPrimaryAcuityPlanPolicy(_ item: PrimaryAcuityPlanPolicy) -> String {
        return classifyTieredFloatPoolPlan(item.effectiveLoad())
    }
}
