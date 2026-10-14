import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessClaimsForCheckpoint(_ items: [WitnessClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveSeasonalLanguageCheckpointsFromClaim(_ items: [WitnessClaim]) -> [SeasonalLanguageCheckpoint] {
        var out: [SeasonalLanguageCheckpoint] = []
        for item in items {
            let derived = newSeasonalLanguageCheckpoint(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateSeasonalLanguageCheckpoint(_ item: SeasonalLanguageCheckpoint) -> String {
        return witnessAuditBucket(item.adjustedLoad())
    }
}
