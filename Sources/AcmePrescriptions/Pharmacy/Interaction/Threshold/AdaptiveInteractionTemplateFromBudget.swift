import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeManualFormularyBudgetsForTemplate(_ items: [ManualFormularyBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveAdaptiveInteractionTemplatesFromBudget(_ items: [ManualFormularyBudget]) -> [AdaptiveInteractionTemplate] {
        var out: [AdaptiveInteractionTemplate] = []
        for item in items {
            let derived = newAdaptiveInteractionTemplate(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileAdaptiveInteractionTemplate(_ item: AdaptiveInteractionTemplate) -> String {
        return classifyRollingFormularySegment(item.weightedLoad())
    }
}
