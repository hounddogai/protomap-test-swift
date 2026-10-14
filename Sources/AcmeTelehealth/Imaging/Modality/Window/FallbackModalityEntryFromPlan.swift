import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyPlansForEntry(_ items: [StudyPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveFallbackModalityEntriesFromPlan(_ items: [StudyPlan]) -> [FallbackModalityEntry] {
        var out: [FallbackModalityEntry] = []
        for item in items {
            let derived = newFallbackModalityEntry(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitFallbackModalityEntry(_ item: FallbackModalityEntry) -> Double {
        return tieredStudyRuleWeight(2, active: true)
    }
}
