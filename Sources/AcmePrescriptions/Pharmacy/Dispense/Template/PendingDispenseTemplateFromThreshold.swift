import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeStrictInteractionThresholdsForTemplate(_ items: [StrictInteractionThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func derivePendingDispenseTemplatesFromThreshold(_ items: [StrictInteractionThreshold]) -> [PendingDispenseTemplate] {
        var out: [PendingDispenseTemplate] = []
        for item in items {
            let derived = newPendingDispenseTemplate(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolvePendingDispenseTemplate(_ item: PendingDispenseTemplate) -> String {
        return classifyAdaptiveInteractionTemplate(item.adjustedTotal())
    }
}
