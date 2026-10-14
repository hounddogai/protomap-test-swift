import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultGoalManifestsForEntry(_ items: [DefaultGoalManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveLegacyRiskScoreEntriesFromManifest(_ items: [DefaultGoalManifest]) -> [LegacyRiskScoreEntry] {
        var out: [LegacyRiskScoreEntry] = []
        for item in items {
            let derived = newLegacyRiskScoreEntry(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeLegacyRiskScoreEntry(_ item: LegacyRiskScoreEntry) -> String {
        return pendingGoalReviewBucket(item.weightedVolume())
    }
}
