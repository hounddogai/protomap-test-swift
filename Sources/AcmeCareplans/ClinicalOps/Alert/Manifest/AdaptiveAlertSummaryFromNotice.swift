import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolNoticesForSummary(_ items: [CareProtocolNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveAdaptiveAlertSummariesFromNotice(_ items: [CareProtocolNotice]) -> [AdaptiveAlertSummary] {
        var out: [AdaptiveAlertSummary] = []
        for item in items {
            let derived = newAdaptiveAlertSummary(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveAlertSummary(_ item: AdaptiveAlertSummary) -> String {
        return normalizeLegacyCareProtocolDigestCode(item.code)
    }
}
