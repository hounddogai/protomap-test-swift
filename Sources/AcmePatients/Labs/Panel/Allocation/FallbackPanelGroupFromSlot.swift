import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeSlotsForGroupAllocation(_ items: [ReferenceRangeSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackPanelGroupsFromSlot(_ items: [ReferenceRangeSlot]) -> [FallbackPanelGroup] {
        var out: [FallbackPanelGroup] = []
        for item in items {
            let derived = newFallbackPanelGroup(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveFallbackPanelGroup(_ item: FallbackPanelGroup) -> String {
        return normalizeLegacyReferenceRangeProfileCode(item.code)
    }
}
