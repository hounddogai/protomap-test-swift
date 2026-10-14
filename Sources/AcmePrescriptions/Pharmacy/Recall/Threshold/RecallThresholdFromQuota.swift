import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeManualSubstitutionQuotasForThreshold(_ items: [ManualSubstitutionQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRecallThresholdsFromQuota(_ items: [ManualSubstitutionQuota]) -> [RecallThreshold] {
        var out: [RecallThreshold] = []
        for item in items {
            let derived = newRecallThreshold(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRecallThreshold(_ item: RecallThreshold) -> String {
        return normalizeSubstitutionReviewCode(item.code)
    }
}
