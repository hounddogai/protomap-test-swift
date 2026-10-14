import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeScheduledCareProtocolThresholdsForBundle(_ items: [ScheduledCareProtocolThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAlertBundlesFromThreshold(_ items: [ScheduledCareProtocolThreshold]) -> [AlertBundle] {
        var out: [AlertBundle] = []
        for item in items {
            let derived = newAlertBundle(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyAlertBundle(_ item: AlertBundle) -> String {
        return normalizeFallbackCareProtocolRollupCode(item.code)
    }
}
