import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackTaskEntriesForManifest(_ items: [FallbackTaskEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveTaskManifestsFromEntry(_ items: [FallbackTaskEntry]) -> [TaskManifest] {
        var out: [TaskManifest] = []
        for item in items {
            let derived = newTaskManifest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateTaskManifest(_ item: TaskManifest) -> String {
        return normalizeTaskReviewCode(item.code)
    }
}
