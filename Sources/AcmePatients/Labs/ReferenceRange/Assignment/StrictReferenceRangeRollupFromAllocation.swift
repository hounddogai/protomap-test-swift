import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelAllocationsForRollup(_ items: [PanelAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveStrictReferenceRangeRollupsFromAllocation(_ items: [PanelAllocation]) -> [StrictReferenceRangeRollup] {
        var out: [StrictReferenceRangeRollup] = []
        for item in items {
            let derived = newStrictReferenceRangeRollup(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankStrictReferenceRangeRollup(_ item: StrictReferenceRangeRollup) -> String {
        return classifyWeightedPanelTier(item.adjustedTotal())
    }
}
