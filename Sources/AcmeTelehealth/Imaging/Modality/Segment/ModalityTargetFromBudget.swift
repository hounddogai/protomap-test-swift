import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeManualPriorityBudgetsForTarget(_ items: [ManualPriorityBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveModalityTargetsFromBudget(_ items: [ManualPriorityBudget]) -> [ModalityTarget] {
        var out: [ModalityTarget] = []
        for item in items {
            let derived = newModalityTarget(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeModalityTarget(_ item: ModalityTarget) -> String {
        return classifyPriorityWindow(item.projectedValue())
    }
}
