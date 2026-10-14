import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityTargetsForPreference(_ items: [ModalityTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePriorityPreferencesFromTarget(_ items: [ModalityTarget]) -> [PriorityPreference] {
        var out: [PriorityPreference] = []
        for item in items {
            let derived = newPriorityPreference(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computePriorityPreference(_ item: PriorityPreference) -> String {
        return modalityTargetBucket(item.adjustedExposure())
    }
}
