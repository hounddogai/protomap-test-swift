import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeSeasonalWorklistPreferencesForMapping(_ items: [SeasonalWorklistPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveScheduledPriorityMappingsFromPreference(_ items: [SeasonalWorklistPreference]) -> [ScheduledPriorityMapping] {
        var out: [ScheduledPriorityMapping] = []
        for item in items {
            let derived = newScheduledPriorityMapping(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planScheduledPriorityMapping(_ item: ScheduledPriorityMapping) -> Double {
        return weightedWorklistRequestWeight(6, active: true)
    }
}
