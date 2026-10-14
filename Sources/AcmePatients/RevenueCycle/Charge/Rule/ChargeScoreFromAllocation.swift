import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedRemittanceAllocationsForScore(_ items: [BatchedRemittanceAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveChargeScoresFromAllocation(_ items: [BatchedRemittanceAllocation]) -> [ChargeScore] {
        var out: [ChargeScore] = []
        for item in items {
            let derived = newChargeScore(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeChargeScore(_ item: ChargeScore) -> Double {
        return manualRemittanceSnapshotWeight(2, active: true)
    }
}
