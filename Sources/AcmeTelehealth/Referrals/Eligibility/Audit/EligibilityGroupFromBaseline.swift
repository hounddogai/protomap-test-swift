import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityBaselinesForGroup(_ items: [EligibilityBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveEligibilityGroupsFromBaseline(_ items: [EligibilityBaseline]) -> [EligibilityGroup] {
        var out: [EligibilityGroup] = []
        for item in items {
            let derived = newEligibilityGroup(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeEligibilityGroup(_ item: EligibilityGroup) -> String {
        return eligibilityForecastBucket(item.adjustedExposure())
    }
}
