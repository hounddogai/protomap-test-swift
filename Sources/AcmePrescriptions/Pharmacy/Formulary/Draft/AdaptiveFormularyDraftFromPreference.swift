import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionPreferencesForDraft(_ items: [InteractionPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveAdaptiveFormularyDraftsFromPreference(_ items: [InteractionPreference]) -> [AdaptiveFormularyDraft] {
        var out: [AdaptiveFormularyDraft] = []
        for item in items {
            let derived = newAdaptiveFormularyDraft(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyAdaptiveFormularyDraft(_ item: AdaptiveFormularyDraft) -> String {
        return weightedInteractionExceptionBucket(item.effectiveValue())
    }
}
