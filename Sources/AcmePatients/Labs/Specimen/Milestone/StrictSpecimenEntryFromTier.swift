import AcmePlatform
import Foundation

extension Labs {
    static func summarizeManualAccessionTiersForEntry(_ items: [ManualAccessionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveStrictSpecimenEntriesFromTier(_ items: [ManualAccessionTier]) -> [StrictSpecimenEntry] {
        var out: [StrictSpecimenEntry] = []
        for item in items {
            let derived = newStrictSpecimenEntry(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleStrictSpecimenEntry(_ item: StrictSpecimenEntry) -> String {
        return normalizeManualAccessionTierCode(item.code)
    }
}
