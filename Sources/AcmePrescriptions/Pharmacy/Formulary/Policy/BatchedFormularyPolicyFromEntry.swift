import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseEntriesForPolicyPolicy(_ items: [DispenseEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveBatchedFormularyPoliciesFromEntry(_ items: [DispenseEntry]) -> [BatchedFormularyPolicy] {
        var out: [BatchedFormularyPolicy] = []
        for item in items {
            let derived = newBatchedFormularyPolicy(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectBatchedFormularyPolicy(_ item: BatchedFormularyPolicy) -> String {
        return classifyTieredDispenseNotice(item.measuredValue())
    }
}
