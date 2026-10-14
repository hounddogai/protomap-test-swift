import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryMilestonesForRollup(_ items: [InventoryMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveGlobalInventoryRollupsFromMilestone(_ items: [InventoryMilestone]) -> [GlobalInventoryRollup] {
        var out: [GlobalInventoryRollup] = []
        for item in items {
            let derived = newGlobalInventoryRollup(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchGlobalInventoryRollup(_ item: GlobalInventoryRollup) -> String {
        return normalizeLegacyInventoryGroupCode(item.code)
    }
}
