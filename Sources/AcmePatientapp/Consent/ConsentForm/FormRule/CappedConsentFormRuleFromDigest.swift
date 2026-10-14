import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledRevocationDigestsForRule(_ items: [ScheduledRevocationDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveCappedConsentFormRulesFromDigest(_ items: [ScheduledRevocationDigest]) -> [CappedConsentFormRule] {
        var out: [CappedConsentFormRule] = []
        for item in items {
            let derived = newCappedConsentFormRule(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateCappedConsentFormRule(_ item: CappedConsentFormRule) -> String {
        return fallbackRevocationTemplateBucket(item.adjustedTotal())
    }
}
