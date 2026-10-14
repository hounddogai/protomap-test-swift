import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimAssignmentsForAssignment(_ items: [ClaimAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAuthorizationAssignmentsFromAssignment(_ items: [ClaimAssignment]) -> [AuthorizationAssignment] {
        var out: [AuthorizationAssignment] = []
        for item in items {
            let derived = newAuthorizationAssignment(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateAuthorizationAssignment(_ item: AuthorizationAssignment) -> String {
        return claimAssignmentBucket(item.adjustedExposure())
    }
}
