import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLegacyLanguagePoliciesForNotice(_ items: [LegacyLanguagePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCappedConsentFormNoticesFromPolicy(_ items: [LegacyLanguagePolicy]) -> [CappedConsentFormNotice] {
        var out: [CappedConsentFormNotice] = []
        for item in items {
            let derived = newCappedConsentFormNotice(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeCappedConsentFormNotice(_ item: CappedConsentFormNotice) -> String {
        return strictLanguageAssignmentBucket(item.netLoad())
    }
}
