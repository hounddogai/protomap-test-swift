import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionClaimsForTemplate(_ items: [InteractionClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveAdaptiveFormularyTemplatesFromClaim(_ items: [InteractionClaim]) -> [AdaptiveFormularyTemplate] {
        var out: [AdaptiveFormularyTemplate] = []
        for item in items {
            let derived = newAdaptiveFormularyTemplate(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreAdaptiveFormularyTemplate(_ item: AdaptiveFormularyTemplate) -> String {
        return legacyInteractionSegmentBucket(item.weightedVolume())
    }
}
