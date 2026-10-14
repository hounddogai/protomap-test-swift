import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacyFormularyRollupsForTarget(_ items: [LegacyFormularyRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveInventoryTargetsFromRollup(_ items: [LegacyFormularyRollup]) -> [InventoryTarget] {
        var out: [InventoryTarget] = []
        for item in items {
            let derived = newInventoryTarget(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchInventoryTarget(_ item: InventoryTarget) -> String {
        return legacyFormularyRollupBucket(item.projectedLoad())
    }
}
