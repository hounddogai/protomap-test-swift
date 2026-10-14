import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageQuotasForAgreement(_ items: [LanguageQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveLanguageAgreementsFromQuota(_ items: [LanguageQuota]) -> [LanguageAgreement] {
        var out: [LanguageAgreement] = []
        for item in items {
            let derived = newLanguageAgreement(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLanguageAgreement(_ item: LanguageAgreement) -> String {
        return adaptiveLanguageTemplateBucket(item.weightedLoad())
    }
}
