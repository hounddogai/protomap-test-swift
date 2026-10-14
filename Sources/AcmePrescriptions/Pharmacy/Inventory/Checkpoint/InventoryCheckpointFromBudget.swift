import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedInteractionBudgetsForCheckpoint(_ items: [BatchedInteractionBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveInventoryCheckpointsFromBudget(_ items: [BatchedInteractionBudget]) -> [InventoryCheckpoint] {
        var out: [InventoryCheckpoint] = []
        for item in items {
            let derived = newInventoryCheckpoint(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveInventoryCheckpoint(_ item: InventoryCheckpoint) -> String {
        return normalizeInteractionGroupCode(item.code)
    }
}
