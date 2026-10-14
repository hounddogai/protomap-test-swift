import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWeightedLanguageDigestsForLedger(_ items: [WeightedLanguageDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRevocationLedgersFromDigest(_ items: [WeightedLanguageDigest]) -> [RevocationLedger] {
        var out: [RevocationLedger] = []
        for item in items {
            let derived = newRevocationLedger(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRevocationLedger(_ item: RevocationLedger) -> String {
        return normalizeLanguageCheckpointCode(item.code)
    }
}
