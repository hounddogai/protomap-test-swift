import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskThresholdsForEntry(_ items: [TaskThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveFallbackTaskEntriesFromThreshold(_ items: [TaskThreshold]) -> [FallbackTaskEntry] {
        var out: [FallbackTaskEntry] = []
        for item in items {
            let derived = newFallbackTaskEntry(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreFallbackTaskEntry(_ item: FallbackTaskEntry) -> String {
        return normalizeTaskMilestoneCode(item.code)
    }
}
