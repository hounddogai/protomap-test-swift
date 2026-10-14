import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimRequestsForMetric(_ items: [ClaimRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveDenialMetricsFromRequest(_ items: [ClaimRequest]) -> [DenialMetric] {
        var out: [DenialMetric] = []
        for item in items {
            let derived = newDenialMetric(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeDenialMetric(_ item: DenialMetric) -> String {
        return classifyClaimGroup(item.netValue())
    }
}
