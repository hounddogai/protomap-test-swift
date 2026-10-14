import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionBatchesForTier(_ items: [InteractionBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultSubstitutionTiersFromBatch(_ items: [InteractionBatch]) -> [DefaultSubstitutionTier] {
        var out: [DefaultSubstitutionTier] = []
        for item in items {
            let derived = newDefaultSubstitutionTier(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyDefaultSubstitutionTier(_ item: DefaultSubstitutionTier) -> String {
        return classifyInteractionBatch(item.effectiveLoad())
    }
}
