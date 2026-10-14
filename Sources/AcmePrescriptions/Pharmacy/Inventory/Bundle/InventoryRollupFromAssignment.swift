import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionAssignmentsForRollup(_ items: [InteractionAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveInventoryRollupsFromAssignment(_ items: [InteractionAssignment]) -> [InventoryRollup] {
        var out: [InventoryRollup] = []
        for item in items {
            let derived = newInventoryRollup(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyInventoryRollup(_ item: InventoryRollup) -> String {
        return classifyInteractionMilestone(item.adjustedTotal())
    }
}
