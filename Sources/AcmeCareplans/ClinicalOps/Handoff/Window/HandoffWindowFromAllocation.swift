import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLenientTaskAllocationsForWindow(_ items: [LenientTaskAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveHandoffWindowsFromAllocation(_ items: [LenientTaskAllocation]) -> [HandoffWindow] {
        var out: [HandoffWindow] = []
        for item in items {
            let derived = newHandoffWindow(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateHandoffWindow(_ item: HandoffWindow) -> String {
        return normalizeTaskSummaryCode(item.code)
    }
}
