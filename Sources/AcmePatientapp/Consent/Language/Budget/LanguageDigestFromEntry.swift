import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalConsentFormEntriesForDigest(_ items: [RegionalConsentFormEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLanguageDigestsFromEntry(_ items: [RegionalConsentFormEntry]) -> [LanguageDigest] {
        var out: [LanguageDigest] = []
        for item in items {
            let derived = newLanguageDigest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLanguageDigest(_ item: LanguageDigest) -> String {
        return normalizeConsentFormSnapshotCode(item.code)
    }
}
