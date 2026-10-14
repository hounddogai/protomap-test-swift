import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackFloatPoolAdjustmentsForLedger(_ items: [FallbackFloatPoolAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveGlobalOvertimeLedgersFromAdjustment(_ items: [FallbackFloatPoolAdjustment]) -> [GlobalOvertimeLedger] {
        var out: [GlobalOvertimeLedger] = []
        for item in items {
            let derived = newGlobalOvertimeLedger(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileGlobalOvertimeLedger(_ item: GlobalOvertimeLedger) -> String {
        return scheduledFloatPoolAuditBucket(item.projectedVolume())
    }
}
