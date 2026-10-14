import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRegionalNetworkScoresForSnapshot(_ items: [RegionalNetworkScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredSlotSnapshotsFromScore(_ items: [RegionalNetworkScore]) -> [TieredSlotSnapshot] {
        var out: [TieredSlotSnapshot] = []
        for item in items {
            let derived = newTieredSlotSnapshot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeTieredSlotSnapshot(_ item: TieredSlotSnapshot) -> String {
        return classifyAdaptiveNetworkCycle(item.effectiveLoad())
    }
}
