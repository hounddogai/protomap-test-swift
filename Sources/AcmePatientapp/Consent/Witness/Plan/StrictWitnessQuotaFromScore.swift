import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageScoresForQuota(_ items: [LanguageScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveStrictWitnessQuotasFromScore(_ items: [LanguageScore]) -> [StrictWitnessQuota] {
        var out: [StrictWitnessQuota] = []
        for item in items {
            let derived = newStrictWitnessQuota(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleStrictWitnessQuota(_ item: StrictWitnessQuota) -> String {
        return classifyStrictLanguageDigest(item.effectiveLoad())
    }
}
