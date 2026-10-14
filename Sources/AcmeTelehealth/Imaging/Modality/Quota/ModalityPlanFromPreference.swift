import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityPreferencesForPlan(_ items: [PriorityPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveModalityPlansFromPreference(_ items: [PriorityPreference]) -> [ModalityPlan] {
        var out: [ModalityPlan] = []
        for item in items {
            let derived = newModalityPlan(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planModalityPlan(_ item: ModalityPlan) -> String {
        return classifyPriorityPreference(item.weightedTotal())
    }
}
