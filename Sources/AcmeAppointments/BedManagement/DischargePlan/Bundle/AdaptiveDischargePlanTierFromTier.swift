import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanTiersForTier(_ items: [DischargePlanTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveAdaptiveDischargePlanTiersFromTier(_ items: [DischargePlanTier]) -> [AdaptiveDischargePlanTier] {
        var out: [AdaptiveDischargePlanTier] = []
        for item in items {
            let derived = newAdaptiveDischargePlanTier(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileAdaptiveDischargePlanTier(_ item: AdaptiveDischargePlanTier) -> String {
        return normalizeDischargePlanAuditCode(item.code)
    }
}
