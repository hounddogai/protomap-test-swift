import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingCareGapAllocationsForNotice(_ items: [PendingCareGapAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveStrictRiskScoreNoticesFromAllocation(_ items: [PendingCareGapAllocation]) -> [StrictRiskScoreNotice] {
        var out: [StrictRiskScoreNotice] = []
        for item in items {
            let derived = newStrictRiskScoreNotice(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileStrictRiskScoreNotice(_ item: StrictRiskScoreNotice) -> Double {
        return adaptiveCareGapOverrideWeight(2, active: true)
    }
}
