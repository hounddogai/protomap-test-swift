import AcmePlatform
import Foundation

extension Consent {
    static func summarizeAdaptiveConsentFormExceptionsForOverride(_ items: [AdaptiveConsentFormException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingProxyOverridesFromException(_ items: [AdaptiveConsentFormException]) -> [RollingProxyOverride] {
        var out: [RollingProxyOverride] = []
        for item in items {
            let derived = newRollingProxyOverride(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRollingProxyOverride(_ item: RollingProxyOverride) -> String {
        return regionalConsentFormThresholdBucket(item.adjustedVolume())
    }
}
