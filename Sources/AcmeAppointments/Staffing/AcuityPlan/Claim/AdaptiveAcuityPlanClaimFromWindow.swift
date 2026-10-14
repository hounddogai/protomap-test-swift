import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftWindowsForClaim(_ items: [ShiftWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveAdaptiveAcuityPlanClaimsFromWindow(_ items: [ShiftWindow]) -> [AdaptiveAcuityPlanClaim] {
        var out: [AdaptiveAcuityPlanClaim] = []
        for item in items {
            let derived = newAdaptiveAcuityPlanClaim(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyAdaptiveAcuityPlanClaim(_ item: AdaptiveAcuityPlanClaim) -> String {
        return shiftWindowBucket(item.adjustedExposure())
    }
}
