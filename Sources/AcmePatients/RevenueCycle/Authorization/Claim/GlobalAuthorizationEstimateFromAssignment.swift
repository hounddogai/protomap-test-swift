import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeFallbackAuthorizationAssignmentsForEstimate(_ items: [FallbackAuthorizationAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveGlobalAuthorizationEstimatesFromAssignment(_ items: [FallbackAuthorizationAssignment]) -> [GlobalAuthorizationEstimate] {
        var out: [GlobalAuthorizationEstimate] = []
        for item in items {
            let derived = newGlobalAuthorizationEstimate(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyGlobalAuthorizationEstimate(_ item: GlobalAuthorizationEstimate) -> String {
        return normalizeAuthorizationOverrideCode(item.code)
    }
}
