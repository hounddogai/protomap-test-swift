import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionRollupsForBatch(_ items: [SubstitutionRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveInventoryBatchesFromRollup(_ items: [SubstitutionRollup]) -> [InventoryBatch] {
        var out: [InventoryBatch] = []
        for item in items {
            let derived = newInventoryBatch(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeInventoryBatch(_ item: InventoryBatch) -> Double {
        return substitutionWindowWeight(1, active: true)
    }
}
