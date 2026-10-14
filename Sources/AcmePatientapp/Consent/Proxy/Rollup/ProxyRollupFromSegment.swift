import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingConsentFormSegmentsForRollup(_ items: [RollingConsentFormSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveProxyRollupsFromSegment(_ items: [RollingConsentFormSegment]) -> [ProxyRollup] {
        var out: [ProxyRollup] = []
        for item in items {
            let derived = newProxyRollup(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeProxyRollup(_ item: ProxyRollup) -> String {
        return pendingConsentFormCheckpointBucket(item.adjustedLoad())
    }
}
