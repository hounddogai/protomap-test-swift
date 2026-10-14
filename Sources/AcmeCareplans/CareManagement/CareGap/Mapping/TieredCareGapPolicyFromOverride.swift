import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapOverridesForPolicy(_ items: [CareGapOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredCareGapPoliciesFromOverride(_ items: [CareGapOverride]) -> [TieredCareGapPolicy] {
        var out: [TieredCareGapPolicy] = []
        for item in items {
            let derived = newTieredCareGapPolicy(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyTieredCareGapPolicy(_ item: TieredCareGapPolicy) -> Double {
        return tieredCareGapScheduleWeight(2, active: true)
    }
}
