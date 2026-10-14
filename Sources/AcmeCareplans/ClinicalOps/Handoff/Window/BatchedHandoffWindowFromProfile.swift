import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingProfilesForWindow(_ items: [RoundingProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveBatchedHandoffWindowsFromProfile(_ items: [RoundingProfile]) -> [BatchedHandoffWindow] {
        var out: [BatchedHandoffWindow] = []
        for item in items {
            let derived = newBatchedHandoffWindow(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyBatchedHandoffWindow(_ item: BatchedHandoffWindow) -> String {
        return normalizeRoundingDraftCode(item.code)
    }
}
