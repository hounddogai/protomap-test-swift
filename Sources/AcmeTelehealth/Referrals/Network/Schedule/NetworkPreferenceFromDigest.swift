import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpDigestsForPreference(_ items: [FollowUpDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveNetworkPreferencesFromDigest(_ items: [FollowUpDigest]) -> [NetworkPreference] {
        var out: [NetworkPreference] = []
        for item in items {
            let derived = newNetworkPreference(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitNetworkPreference(_ item: NetworkPreference) -> String {
        return followUpBaselineBucket(item.projectedExposure())
    }
}
