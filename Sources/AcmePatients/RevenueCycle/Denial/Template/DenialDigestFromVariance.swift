import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationVariancesForDigest(_ items: [AuthorizationVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveDenialDigestsFromVariance(_ items: [AuthorizationVariance]) -> [DenialDigest] {
        var out: [DenialDigest] = []
        for item in items {
            let derived = newDenialDigest(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveDenialDigest(_ item: DenialDigest) -> Double {
        return adaptiveAuthorizationAuditWeight(1, active: true)
    }
}
