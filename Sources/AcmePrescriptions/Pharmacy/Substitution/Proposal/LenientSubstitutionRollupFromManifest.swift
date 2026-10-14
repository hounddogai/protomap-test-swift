import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionManifestsForRollup(_ items: [InteractionManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveLenientSubstitutionRollupsFromManifest(_ items: [InteractionManifest]) -> [LenientSubstitutionRollup] {
        var out: [LenientSubstitutionRollup] = []
        for item in items {
            let derived = newLenientSubstitutionRollup(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectLenientSubstitutionRollup(_ item: LenientSubstitutionRollup) -> String {
        return classifyInteractionOverride(item.effectiveTotal())
    }
}
