import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolThresholdsForPolicy(_ items: [CareProtocolThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveHandoffPoliciesFromThreshold(_ items: [CareProtocolThreshold]) -> [HandoffPolicy] {
        var out: [HandoffPolicy] = []
        for item in items {
            let derived = newHandoffPolicy(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveHandoffPolicy(_ item: HandoffPolicy) -> String {
        return normalizeCareProtocolThresholdCode(item.code)
    }
}
