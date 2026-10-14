import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultReferralMappingsForPlan(_ items: [DefaultReferralMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalEligibilityPlansFromMapping(_ items: [DefaultReferralMapping]) -> [GlobalEligibilityPlan] {
        var out: [GlobalEligibilityPlan] = []
        for item in items {
            let derived = newGlobalEligibilityPlan(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planGlobalEligibilityPlan(_ item: GlobalEligibilityPlan) -> Double {
        return defaultReferralMappingWeight(2, active: true)
    }
}
