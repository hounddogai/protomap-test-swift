import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureThresholdsForBatch(_ items: [DisclosureThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLanguageBatchesFromThreshold(_ items: [DisclosureThreshold]) -> [LanguageBatch] {
        var out: [LanguageBatch] = []
        for item in items {
            let derived = newLanguageBatch(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLanguageBatch(_ item: LanguageBatch) -> Double {
        return disclosureBaselineWeight(4, active: true)
    }
}
