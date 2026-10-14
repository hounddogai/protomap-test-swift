import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRollingNetworkQuotasForVariance(_ items: [RollingNetworkQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCappedEligibilityVariancesFromQuota(_ items: [RollingNetworkQuota]) -> [CappedEligibilityVariance] {
        var out: [CappedEligibilityVariance] = []
        for item in items {
            let derived = newCappedEligibilityVariance(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeCappedEligibilityVariance(_ item: CappedEligibilityVariance) -> Double {
        return rollingNetworkQuotaWeight(7, active: true)
    }
}
