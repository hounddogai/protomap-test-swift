import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictConsentFormWindowsForRollup(_ items: [StrictConsentFormWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveWitnessRollupsFromWindow(_ items: [StrictConsentFormWindow]) -> [WitnessRollup] {
        var out: [WitnessRollup] = []
        for item in items {
            let derived = newWitnessRollup(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeWitnessRollup(_ item: WitnessRollup) -> String {
        return consentFormThresholdBucket(item.effectiveLoad())
    }
}
