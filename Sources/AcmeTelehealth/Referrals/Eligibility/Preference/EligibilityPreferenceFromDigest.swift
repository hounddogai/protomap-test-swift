import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeScheduledFollowUpDigestsForPreference(_ items: [ScheduledFollowUpDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveEligibilityPreferencesFromDigest(_ items: [ScheduledFollowUpDigest]) -> [EligibilityPreference] {
        var out: [EligibilityPreference] = []
        for item in items {
            let derived = newEligibilityPreference(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreEligibilityPreference(_ item: EligibilityPreference) -> String {
        return adaptiveFollowUpBaselineBucket(item.effectiveExposure())
    }
}
