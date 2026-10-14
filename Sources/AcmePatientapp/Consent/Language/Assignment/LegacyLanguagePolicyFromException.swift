import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledRevocationExceptionsForPolicy(_ items: [ScheduledRevocationException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyLanguagePoliciesFromException(_ items: [ScheduledRevocationException]) -> [LegacyLanguagePolicy] {
        var out: [LegacyLanguagePolicy] = []
        for item in items {
            let derived = newLegacyLanguagePolicy(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreLegacyLanguagePolicy(_ item: LegacyLanguagePolicy) -> String {
        return classifyTieredRevocationRollup(item.projectedValue())
    }
}
