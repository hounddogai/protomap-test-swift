import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLegacyOvertimePoliciesForRequest(_ items: [LegacyOvertimePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePrimaryAcuityPlanRequestsFromPolicy(_ items: [LegacyOvertimePolicy]) -> [PrimaryAcuityPlanRequest] {
        var out: [PrimaryAcuityPlanRequest] = []
        for item in items {
            let derived = newPrimaryAcuityPlanRequest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyPrimaryAcuityPlanRequest(_ item: PrimaryAcuityPlanRequest) -> String {
        return normalizeAdaptiveOvertimeBudgetCode(item.code)
    }
}
