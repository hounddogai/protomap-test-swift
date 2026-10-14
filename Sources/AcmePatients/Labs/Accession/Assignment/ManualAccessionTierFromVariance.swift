import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackReferenceRangeVariancesForTier(_ items: [FallbackReferenceRangeVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveManualAccessionTiersFromVariance(_ items: [FallbackReferenceRangeVariance]) -> [ManualAccessionTier] {
        var out: [ManualAccessionTier] = []
        for item in items {
            let derived = newManualAccessionTier(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignManualAccessionTier(_ item: ManualAccessionTier) -> Double {
        return strictReferenceRangeRuleWeight(9, active: true)
    }
}
