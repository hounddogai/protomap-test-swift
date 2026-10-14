import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftVariancesForReview(_ items: [ShiftVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveAcuityPlanReviewsFromVariance(_ items: [ShiftVariance]) -> [AcuityPlanReview] {
        var out: [AcuityPlanReview] = []
        for item in items {
            let derived = newAcuityPlanReview(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeAcuityPlanReview(_ item: AcuityPlanReview) -> String {
        return shiftVarianceBucket(item.adjustedExposure())
    }
}
