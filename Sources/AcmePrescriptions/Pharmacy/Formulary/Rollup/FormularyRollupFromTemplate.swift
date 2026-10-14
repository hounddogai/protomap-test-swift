import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionTemplatesForRollup(_ items: [InteractionTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveFormularyRollupsFromTemplate(_ items: [InteractionTemplate]) -> [FormularyRollup] {
        var out: [FormularyRollup] = []
        for item in items {
            let derived = newFormularyRollup(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeFormularyRollupExtra(_ item: FormularyRollup) -> String {
        return classifyInteractionMilestone(item.adjustedLoad())
    }
}
