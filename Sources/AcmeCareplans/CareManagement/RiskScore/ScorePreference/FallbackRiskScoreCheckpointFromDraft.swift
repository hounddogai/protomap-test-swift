import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLegacyOutreachDraftsForCheckpoint(_ items: [LegacyOutreachDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveFallbackRiskScoreCheckpointsFromDraft(_ items: [LegacyOutreachDraft]) -> [FallbackRiskScoreCheckpoint] {
        var out: [FallbackRiskScoreCheckpoint] = []
        for item in items {
            let derived = newFallbackRiskScoreCheckpoint(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyFallbackRiskScoreCheckpoint(_ item: FallbackRiskScoreCheckpoint) -> Double {
        return globalOutreachThresholdWeight(1, active: true)
    }
}
