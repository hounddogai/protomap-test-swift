import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionManifestsForTemplate(_ items: [SubstitutionManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveAdaptiveInteractionTemplatesFromManifest(_ items: [SubstitutionManifest]) -> [AdaptiveInteractionTemplate] {
        var out: [AdaptiveInteractionTemplate] = []
        for item in items {
            let derived = newAdaptiveInteractionTemplate(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankAdaptiveInteractionTemplate(_ item: AdaptiveInteractionTemplate) -> String {
        return classifySubstitutionMilestone(item.weightedLoad())
    }
}
