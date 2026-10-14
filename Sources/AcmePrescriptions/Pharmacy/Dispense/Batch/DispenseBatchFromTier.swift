import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionTiersForBatch(_ items: [SubstitutionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDispenseBatchesFromTier(_ items: [SubstitutionTier]) -> [DispenseBatch] {
        var out: [DispenseBatch] = []
        for item in items {
            let derived = newDispenseBatch(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeDispenseBatch(_ item: DispenseBatch) -> String {
        return substitutionScoreBucket(item.effectiveTotal())
    }
}
