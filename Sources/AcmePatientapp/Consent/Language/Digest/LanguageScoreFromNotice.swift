import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureNoticesForScore(_ items: [DisclosureNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveLanguageScoresFromNotice(_ items: [DisclosureNotice]) -> [LanguageScore] {
        var out: [LanguageScore] = []
        for item in items {
            let derived = newLanguageScore(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectLanguageScore(_ item: LanguageScore) -> String {
        return disclosureRequestBucket(item.adjustedLoad())
    }
}
