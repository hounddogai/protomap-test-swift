import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftAssignmentsForClaim(_ items: [ShiftAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRegionalCredentialClaimsFromAssignment(_ items: [ShiftAssignment]) -> [RegionalCredentialClaim] {
        var out: [RegionalCredentialClaim] = []
        for item in items {
            let derived = newRegionalCredentialClaim(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRegionalCredentialClaim(_ item: RegionalCredentialClaim) -> String {
        return globalShiftProfileBucket(item.effectiveExposure())
    }
}
