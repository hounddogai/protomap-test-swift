import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalReferralMappingsForScore(_ items: [SeasonalReferralMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualClosureScoresFromMapping(_ items: [SeasonalReferralMapping]) -> [ManualClosureScore] {
        var out: [ManualClosureScore] = []
        for item in items {
            let derived = newManualClosureScore(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitManualClosureScore(_ item: ManualClosureScore) -> String {
        return strictReferralPreferenceBucket(item.netExposure())
    }
}
