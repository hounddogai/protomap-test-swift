import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeFallbackRemittanceClaimsForBundle(_ items: [FallbackRemittanceClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDenialBundlesFromClaim(_ items: [FallbackRemittanceClaim]) -> [DenialBundle] {
        var out: [DenialBundle] = []
        for item in items {
            let derived = newDenialBundle(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleDenialBundle(_ item: DenialBundle) -> Double {
        return fallbackRemittanceClaimWeight(8, active: true)
    }
}
