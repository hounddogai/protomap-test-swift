import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedDispensePoliciesForDigest(_ items: [BatchedDispensePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualFormularyDigestsFromPolicy(_ items: [BatchedDispensePolicy]) -> [ManualFormularyDigest] {
        var out: [ManualFormularyDigest] = []
        for item in items {
            let derived = newManualFormularyDigest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateManualFormularyDigest(_ item: ManualFormularyDigest) -> Double {
        return batchedDispensePolicyWeight(2, active: true)
    }
}
