import AcmePlatform
import Foundation

extension Consent {
    static func summarizeSeasonalLanguageCheckpointsForBundle(_ items: [SeasonalLanguageCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveBatchedLanguageBundlesFromCheckpoint(_ items: [SeasonalLanguageCheckpoint]) -> [BatchedLanguageBundle] {
        var out: [BatchedLanguageBundle] = []
        for item in items {
            let derived = newBatchedLanguageBundle(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceBatchedLanguageBundle(_ item: BatchedLanguageBundle) -> Double {
        return languageBundleWeight(8, active: true)
    }
}
