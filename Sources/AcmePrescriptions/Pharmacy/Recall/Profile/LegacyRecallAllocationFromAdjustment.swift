import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionAdjustmentsForAllocation(_ items: [InteractionAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyRecallAllocationsFromAdjustment(_ items: [InteractionAdjustment]) -> [LegacyRecallAllocation] {
        var out: [LegacyRecallAllocation] = []
        for item in items {
            let derived = newLegacyRecallAllocation(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreLegacyRecallAllocation(_ item: LegacyRecallAllocation) -> String {
        return classifyLegacyInteractionTier(item.projectedValue())
    }
}
