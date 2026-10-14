import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeThresholdsForException(_ items: [ChargeThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveFallbackChargeExceptionsFromThreshold(_ items: [ChargeThreshold]) -> [FallbackChargeException] {
        var out: [FallbackChargeException] = []
        for item in items {
            let derived = newFallbackChargeException(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeFallbackChargeException(_ item: FallbackChargeException) -> String {
        return chargeThresholdBucket(item.adjustedLoad())
    }
}
