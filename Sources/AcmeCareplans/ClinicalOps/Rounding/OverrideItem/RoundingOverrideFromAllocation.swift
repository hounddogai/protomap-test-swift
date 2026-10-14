import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLenientTaskAllocationsForOverride(_ items: [LenientTaskAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveRoundingOverridesFromAllocation(_ items: [LenientTaskAllocation]) -> [RoundingOverride] {
        var out: [RoundingOverride] = []
        for item in items {
            let derived = newRoundingOverride(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRoundingOverride(_ item: RoundingOverride) -> String {
        return normalizeTaskSummaryCode(item.code)
    }
}
