import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingProgramEstimatesForPlan(_ items: [PendingProgramEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func derivePendingOutreachPlansFromEstimate(_ items: [PendingProgramEstimate]) -> [PendingOutreachPlan] {
        var out: [PendingOutreachPlan] = []
        for item in items {
            let derived = newPendingOutreachPlan(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPendingOutreachPlan(_ item: PendingOutreachPlan) -> Double {
        return globalProgramPreferenceWeight(8, active: true)
    }
}
