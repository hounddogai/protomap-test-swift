import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingPriorityBudgetsForThreshold(_ items: [RollingPriorityBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveModalityThresholdsFromBudget(_ items: [RollingPriorityBudget]) -> [ModalityThreshold] {
        var out: [ModalityThreshold] = []
        for item in items {
            let derived = newModalityThreshold(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleModalityThreshold(_ item: ModalityThreshold) -> String {
        return classifyAdaptivePriorityMilestone(item.adjustedVolume())
    }
}
