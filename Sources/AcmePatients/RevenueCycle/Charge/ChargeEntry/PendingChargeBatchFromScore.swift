import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeScoresForBatch(_ items: [ChargeScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func derivePendingChargeBatchesFromScore(_ items: [ChargeScore]) -> [PendingChargeBatch] {
        var out: [PendingChargeBatch] = []
        for item in items {
            let derived = newPendingChargeBatch(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scorePendingChargeBatch(_ item: PendingChargeBatch) -> String {
        return classifyChargeRule(item.measuredValue())
    }
}
