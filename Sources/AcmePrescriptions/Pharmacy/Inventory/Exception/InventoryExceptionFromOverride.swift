import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLenientInventoryOverridesForException(_ items: [LenientInventoryOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveInventoryExceptionsFromOverride(_ items: [LenientInventoryOverride]) -> [InventoryException] {
        var out: [InventoryException] = []
        for item in items {
            let derived = newInventoryException(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleInventoryException(_ item: InventoryException) -> String {
        return normalizeLenientInventoryOverrideCode(item.code)
    }
}
