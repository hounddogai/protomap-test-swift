import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStrictRemittanceAllocationsForAssignment(_ items: [StrictRemittanceAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveFallbackAuthorizationAssignmentsFromAllocation(_ items: [StrictRemittanceAllocation]) -> [FallbackAuthorizationAssignment] {
        var out: [FallbackAuthorizationAssignment] = []
        for item in items {
            let derived = newFallbackAuthorizationAssignment(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planFallbackAuthorizationAssignment(_ item: FallbackAuthorizationAssignment) -> String {
        return normalizeRemittanceQuotaCode(item.code)
    }
}
