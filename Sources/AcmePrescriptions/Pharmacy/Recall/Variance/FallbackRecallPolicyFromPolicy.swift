import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedFormularyPoliciesForPolicy(_ items: [BatchedFormularyPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackRecallPoliciesFromPolicy(_ items: [BatchedFormularyPolicy]) -> [FallbackRecallPolicy] {
        var out: [FallbackRecallPolicy] = []
        for item in items {
            let derived = newFallbackRecallPolicy(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateFallbackRecallPolicy(_ item: FallbackRecallPolicy) -> String {
        return manualFormularyRollupBucket(item.projectedValue())
    }
}
