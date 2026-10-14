import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeManualWorklistDigestsForScore(_ items: [ManualWorklistDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveWorklistScoresFromDigest(_ items: [ManualWorklistDigest]) -> [WorklistScore] {
        var out: [WorklistScore] = []
        for item in items {
            let derived = newWorklistScore(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignWorklistScore(_ item: WorklistScore) -> String {
        return normalizeStrictWorklistClaimCode(item.code)
    }
}
