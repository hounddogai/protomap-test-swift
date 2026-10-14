import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeCappedRecallSnapshotsForTier(_ items: [CappedRecallSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveLenientSubstitutionTiersFromSnapshot(_ items: [CappedRecallSnapshot]) -> [LenientSubstitutionTier] {
        var out: [LenientSubstitutionTier] = []
        for item in items {
            let derived = newLenientSubstitutionTier(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyLenientSubstitutionTier(_ item: LenientSubstitutionTier) -> String {
        return normalizeCappedRecallSnapshotCode(item.code)
    }
}
