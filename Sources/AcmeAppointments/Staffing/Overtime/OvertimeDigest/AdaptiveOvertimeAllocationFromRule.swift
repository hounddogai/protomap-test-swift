import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialRulesForAllocation(_ items: [CredentialRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveAdaptiveOvertimeAllocationsFromRule(_ items: [CredentialRule]) -> [AdaptiveOvertimeAllocation] {
        var out: [AdaptiveOvertimeAllocation] = []
        for item in items {
            let derived = newAdaptiveOvertimeAllocation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateAdaptiveOvertimeAllocation(_ item: AdaptiveOvertimeAllocation) -> String {
        return classifyPendingCredentialEntry(item.adjustedExposure())
    }
}
