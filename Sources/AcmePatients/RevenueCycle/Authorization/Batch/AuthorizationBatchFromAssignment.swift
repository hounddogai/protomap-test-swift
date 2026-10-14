import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationAssignmentsForBatch(_ items: [AuthorizationAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveAuthorizationBatchesFromAssignment(_ items: [AuthorizationAssignment]) -> [AuthorizationBatch] {
        var out: [AuthorizationBatch] = []
        for item in items {
            let derived = newAuthorizationBatch(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveAuthorizationBatch(_ item: AuthorizationBatch) -> String {
        return normalizeAuthorizationTierCode(item.code)
    }
}
