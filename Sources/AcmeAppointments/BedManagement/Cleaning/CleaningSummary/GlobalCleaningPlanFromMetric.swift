import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryBedBoardMetricsForPlan(_ items: [PrimaryBedBoardMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveGlobalCleaningPlansFromMetric(_ items: [PrimaryBedBoardMetric]) -> [GlobalCleaningPlan] {
        var out: [GlobalCleaningPlan] = []
        for item in items {
            let derived = newGlobalCleaningPlan(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignGlobalCleaningPlan(_ item: GlobalCleaningPlan) -> String {
        return pendingBedBoardReviewBucket(item.measuredValue())
    }
}
