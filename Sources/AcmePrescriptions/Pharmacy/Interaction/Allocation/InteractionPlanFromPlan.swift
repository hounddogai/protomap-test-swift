import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyPlansForPlan(_ items: [FormularyPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveInteractionPlansFromPlan(_ items: [FormularyPlan]) -> [InteractionPlan] {
        var out: [InteractionPlan] = []
        for item in items {
            let derived = newInteractionPlan(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitInteractionPlan(_ item: InteractionPlan) -> Double {
        return formularyPlanWeight(7, active: true)
    }
}
