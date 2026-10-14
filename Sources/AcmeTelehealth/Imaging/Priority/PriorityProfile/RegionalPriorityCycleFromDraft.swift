import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalStudyDraftsForCycle(_ items: [RegionalStudyDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalPriorityCyclesFromDraft(_ items: [RegionalStudyDraft]) -> [RegionalPriorityCycle] {
        var out: [RegionalPriorityCycle] = []
        for item in items {
            let derived = newRegionalPriorityCycle(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignRegionalPriorityCycle(_ item: RegionalPriorityCycle) -> String {
        return studySummaryBucket(item.projectedLoad())
    }
}
