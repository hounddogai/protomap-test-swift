import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyGroupsForBatch(_ items: [FormularyGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveInventoryBatchesFromGroup(_ items: [FormularyGroup]) -> [InventoryBatch] {
        var out: [InventoryBatch] = []
        for item in items {
            let derived = newInventoryBatch(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planInventoryBatch(_ item: InventoryBatch) -> String {
        return classifyFormularyVariance(item.projectedValue())
    }
}
