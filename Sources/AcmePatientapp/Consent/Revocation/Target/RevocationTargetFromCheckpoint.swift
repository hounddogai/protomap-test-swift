import AcmePlatform
import Foundation

extension Consent {
    static func summarizeSeasonalLanguageCheckpointsForTarget(_ items: [SeasonalLanguageCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRevocationTargetsFromCheckpoint(_ items: [SeasonalLanguageCheckpoint]) -> [RevocationTarget] {
        var out: [RevocationTarget] = []
        for item in items {
            let derived = newRevocationTarget(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleRevocationTarget(_ item: RevocationTarget) -> String {
        return languageBundleBucket(item.effectiveValue())
    }
}
