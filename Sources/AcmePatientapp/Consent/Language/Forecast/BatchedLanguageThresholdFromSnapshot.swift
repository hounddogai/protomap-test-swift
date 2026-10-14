import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageSnapshotsForThreshold(_ items: [LanguageSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedLanguageThresholdsFromSnapshot(_ items: [LanguageSnapshot]) -> [BatchedLanguageThreshold] {
        var out: [BatchedLanguageThreshold] = []
        for item in items {
            let derived = newBatchedLanguageThreshold(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreBatchedLanguageThreshold(_ item: BatchedLanguageThreshold) -> Double {
        return languageSnapshotWeight(5, active: true)
    }
}
