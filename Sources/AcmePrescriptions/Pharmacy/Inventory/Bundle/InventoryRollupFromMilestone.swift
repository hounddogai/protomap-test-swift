import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallMilestonesForRollup(_ items: [RecallMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveInventoryRollupsFromMilestone(_ items: [RecallMilestone]) -> [InventoryRollup] {
        var out: [InventoryRollup] = []
        for item in items {
            let derived = newInventoryRollup(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceInventoryRollup(_ item: InventoryRollup) -> Double {
        return recallTemplateWeight(9, active: true)
    }
}
