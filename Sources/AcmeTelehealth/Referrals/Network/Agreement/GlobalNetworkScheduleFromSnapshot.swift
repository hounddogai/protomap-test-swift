import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredSlotSnapshotsForSchedule(_ items: [TieredSlotSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveGlobalNetworkSchedulesFromSnapshot(_ items: [TieredSlotSnapshot]) -> [GlobalNetworkSchedule] {
        var out: [GlobalNetworkSchedule] = []
        for item in items {
            let derived = newGlobalNetworkSchedule(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateGlobalNetworkSchedule(_ item: GlobalNetworkSchedule) -> String {
        return normalizeGlobalSlotEstimateCode(item.code)
    }
}
