import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanCyclesForRule(_ items: [AcuityPlanCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveAcuityPlanRulesFromCycle(_ items: [AcuityPlanCycle]) -> [AcuityPlanRule] {
        var out: [AcuityPlanRule] = []
        for item in items {
            let derived = newAcuityPlanRule(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateAcuityPlanRule(_ item: AcuityPlanRule) -> String {
        return acuityPlanRequestBucket(item.effectiveLoad())
    }
}
