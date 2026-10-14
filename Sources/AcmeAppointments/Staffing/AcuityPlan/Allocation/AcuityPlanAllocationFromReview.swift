import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanReviewsForAllocationAllocation(_ items: [AcuityPlanReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveAcuityPlanAllocationsFromReview(_ items: [AcuityPlanReview]) -> [AcuityPlanAllocation] {
        var out: [AcuityPlanAllocation] = []
        for item in items {
            let derived = newAcuityPlanAllocation(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchAcuityPlanAllocation(_ item: AcuityPlanAllocation) -> String {
        return primaryAcuityPlanRequestBucket(item.adjustedExposure())
    }
}
