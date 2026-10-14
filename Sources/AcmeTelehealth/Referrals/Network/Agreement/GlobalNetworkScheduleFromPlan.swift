import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFallbackEligibilityPlansForSchedule(_ items: [FallbackEligibilityPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalNetworkSchedulesFromPlan(_ items: [FallbackEligibilityPlan]) -> [GlobalNetworkSchedule] {
        var out: [GlobalNetworkSchedule] = []
        for item in items {
            let derived = newGlobalNetworkSchedule(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planGlobalNetworkSchedule(_ item: GlobalNetworkSchedule) -> Double {
        return batchedEligibilityVarianceWeight(1, active: true)
    }
}
