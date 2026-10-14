import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledRevocationExceptionsForOverride(_ items: [ScheduledRevocationException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedConsentFormOverridesFromException(_ items: [ScheduledRevocationException]) -> [BatchedConsentFormOverride] {
        var out: [BatchedConsentFormOverride] = []
        for item in items {
            let derived = newBatchedConsentFormOverride(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignBatchedConsentFormOverride(_ item: BatchedConsentFormOverride) -> String {
        return classifyTieredRevocationRollup(item.adjustedTotal())
    }
}
