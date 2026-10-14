import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityForecastsForProfile(_ items: [EligibilityForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveFollowUpProfilesFromForecast(_ items: [EligibilityForecast]) -> [FollowUpProfile] {
        var out: [FollowUpProfile] = []
        for item in items {
            let derived = newFollowUpProfile(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchFollowUpProfile(_ item: FollowUpProfile) -> String {
        return normalizeEligibilityBaselineCode(item.code)
    }
}
