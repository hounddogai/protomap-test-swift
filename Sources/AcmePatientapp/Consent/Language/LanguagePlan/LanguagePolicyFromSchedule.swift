import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormSchedulesForPolicy(_ items: [ConsentFormSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveLanguagePoliciesFromSchedule(_ items: [ConsentFormSchedule]) -> [LanguagePolicy] {
        var out: [LanguagePolicy] = []
        for item in items {
            let derived = newLanguagePolicy(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLanguagePolicy(_ item: LanguagePolicy) -> String {
        return classifyConsentFormRecord(item.weightedExposure())
    }
}
