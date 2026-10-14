import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryClosureAssignmentsForClaim(_ items: [PrimaryClosureAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRegionalClosureClaimsFromAssignment(_ items: [PrimaryClosureAssignment]) -> [RegionalClosureClaim] {
        var out: [RegionalClosureClaim] = []
        for item in items {
            let derived = newRegionalClosureClaim(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyRegionalClosureClaim(_ item: RegionalClosureClaim) -> Double {
        return manualClosureSnapshotWeight(6, active: true)
    }
}
