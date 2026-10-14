import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyRoundingMappingsForAllocation(_ items: [LegacyRoundingMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveHandoffAllocationsFromMapping(_ items: [LegacyRoundingMapping]) -> [HandoffAllocation] {
        var out: [HandoffAllocation] = []
        for item in items {
            let derived = newHandoffAllocation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }
}
