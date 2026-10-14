import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionThresholdsForTier(_ items: [InteractionThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveSubstitutionTiersFromThreshold(_ items: [InteractionThreshold]) -> [SubstitutionTier] {
        var out: [SubstitutionTier] = []
        for item in items {
            let derived = newSubstitutionTier(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeSubstitutionTier(_ item: SubstitutionTier) -> String {
        return interactionLedgerBucket(item.adjustedValue())
    }
}
