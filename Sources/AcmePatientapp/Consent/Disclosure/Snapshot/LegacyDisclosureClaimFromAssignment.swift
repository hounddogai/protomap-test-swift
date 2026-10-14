import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingWitnessAssignmentsForClaim(_ items: [RollingWitnessAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveLegacyDisclosureClaimsFromAssignment(_ items: [RollingWitnessAssignment]) -> [LegacyDisclosureClaim] {
        var out: [LegacyDisclosureClaim] = []
        for item in items {
            let derived = newLegacyDisclosureClaim(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateLegacyDisclosureClaim(_ item: LegacyDisclosureClaim) -> Double {
        return rollingWitnessAssignmentWeight(6, active: true)
    }
}
