import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessQuotasForEstimate(_ items: [WitnessQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLanguageEstimatesFromQuota(_ items: [WitnessQuota]) -> [LanguageEstimate] {
        var out: [LanguageEstimate] = []
        for item in items {
            let derived = newLanguageEstimate(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyLanguageEstimate(_ item: LanguageEstimate) -> String {
        return witnessQuotaBucket(item.weightedValue())
    }
}
