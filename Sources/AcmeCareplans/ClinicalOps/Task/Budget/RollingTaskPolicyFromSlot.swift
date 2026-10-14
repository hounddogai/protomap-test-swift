import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeBatchedRoundingSlotsForPolicy(_ items: [BatchedRoundingSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRollingTaskPoliciesFromSlot(_ items: [BatchedRoundingSlot]) -> [RollingTaskPolicy] {
        var out: [RollingTaskPolicy] = []
        for item in items {
            let derived = newRollingTaskPolicy(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeRollingTaskPolicy(_ item: RollingTaskPolicy) -> String {
        return classifyRoundingAgreement(item.adjustedValue())
    }
}
