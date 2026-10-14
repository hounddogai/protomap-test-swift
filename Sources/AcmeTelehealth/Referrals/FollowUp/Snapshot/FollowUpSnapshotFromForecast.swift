import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveEligibilityForecastsForSnapshot(_ items: [AdaptiveEligibilityForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveFollowUpSnapshotsFromForecast(_ items: [AdaptiveEligibilityForecast]) -> [FollowUpSnapshot] {
        var out: [FollowUpSnapshot] = []
        for item in items {
            let derived = newFollowUpSnapshot(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeFollowUpSnapshot(_ item: FollowUpSnapshot) -> String {
        return batchedEligibilityScoreBucket(item.adjustedVolume())
    }
}
