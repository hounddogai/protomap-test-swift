import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionScoresForPolicy(_ items: [InteractionScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveBatchedFormularyPoliciesFromScore(_ items: [InteractionScore]) -> [BatchedFormularyPolicy] {
        var out: [BatchedFormularyPolicy] = []
        for item in items {
            let derived = newBatchedFormularyPolicy(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleBatchedFormularyPolicy(_ item: BatchedFormularyPolicy) -> String {
        return normalizeAdaptiveInteractionRecordCode(item.code)
    }
}
