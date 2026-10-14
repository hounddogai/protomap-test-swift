import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingProgramEstimatesForPolicy(_ items: [PendingProgramEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveScheduledCareGapPoliciesFromEstimate(_ items: [PendingProgramEstimate]) -> [ScheduledCareGapPolicy] {
        var out: [ScheduledCareGapPolicy] = []
        for item in items {
            let derived = newScheduledCareGapPolicy(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeScheduledCareGapPolicy(_ item: ScheduledCareGapPolicy) -> Double {
        return manualProgramBundleWeight(8, active: true)
    }
}
