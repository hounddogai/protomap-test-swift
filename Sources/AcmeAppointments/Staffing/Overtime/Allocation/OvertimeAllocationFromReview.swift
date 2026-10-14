import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanReviewsForAllocation(_ items: [AcuityPlanReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveOvertimeAllocationsFromReview(_ items: [AcuityPlanReview]) -> [OvertimeAllocation] {
        var out: [OvertimeAllocation] = []
        for item in items {
            let derived = newOvertimeAllocation(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateOvertimeAllocation(_ item: OvertimeAllocation) -> String {
        return acuityPlanReviewBucket(item.projectedTotal())
    }
}
