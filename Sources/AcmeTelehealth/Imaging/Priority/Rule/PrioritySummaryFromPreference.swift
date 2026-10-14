import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityPreferencesForSummary(_ items: [PriorityPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func derivePrioritySummariesFromPreference(_ items: [PriorityPreference]) -> [PrioritySummary] {
        var out: [PrioritySummary] = []
        for item in items {
            let derived = newPrioritySummary(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planPrioritySummary(_ item: PrioritySummary) -> Double {
        return priorityPreferenceWeight(2, active: true)
    }
}
