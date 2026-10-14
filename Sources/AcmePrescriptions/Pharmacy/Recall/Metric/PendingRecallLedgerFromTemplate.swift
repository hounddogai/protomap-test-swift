import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFallbackRecallTemplatesForLedger(_ items: [FallbackRecallTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func derivePendingRecallLedgersFromTemplate(_ items: [FallbackRecallTemplate]) -> [PendingRecallLedger] {
        var out: [PendingRecallLedger] = []
        for item in items {
            let derived = newPendingRecallLedger(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcilePendingRecallLedger(_ item: PendingRecallLedger) -> Double {
        return manualRecallQuotaWeight(9, active: true)
    }
}
