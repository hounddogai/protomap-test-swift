import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanPoliciesForSummary(_ items: [AcuityPlanPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveShiftSummariesFromPolicy(_ items: [AcuityPlanPolicy]) -> [ShiftSummary] {
        var out: [ShiftSummary] = []
        for item in items {
            let derived = newShiftSummary(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeShiftSummary(_ item: ShiftSummary) -> Double {
        return acuityPlanPolicyWeight(2, active: true)
    }
}
