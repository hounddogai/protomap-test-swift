import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePendingChargeQuotasForTemplate(_ items: [PendingChargeQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveAdaptiveClaimTemplatesFromQuota(_ items: [PendingChargeQuota]) -> [AdaptiveClaimTemplate] {
        var out: [AdaptiveClaimTemplate] = []
        for item in items {
            let derived = newAdaptiveClaimTemplate(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAdaptiveClaimTemplate(_ item: AdaptiveClaimTemplate) -> String {
        return normalizeStrictChargeGroupCode(item.code)
    }
}
