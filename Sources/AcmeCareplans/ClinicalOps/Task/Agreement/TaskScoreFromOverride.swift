import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTieredTaskOverridesForScore(_ items: [TieredTaskOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveTaskScoresFromOverride(_ items: [TieredTaskOverride]) -> [TaskScore] {
        var out: [TaskScore] = []
        for item in items {
            let derived = newTaskScore(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeTaskScore(_ item: TaskScore) -> String {
        return normalizeTaskDigestCode(item.code)
    }
}
