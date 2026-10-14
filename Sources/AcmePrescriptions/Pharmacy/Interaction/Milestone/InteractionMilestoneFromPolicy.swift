import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionPoliciesForMilestone(_ items: [SubstitutionPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveInteractionMilestonesFromPolicy(_ items: [SubstitutionPolicy]) -> [InteractionMilestone] {
        var out: [InteractionMilestone] = []
        for item in items {
            let derived = newInteractionMilestone(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyInteractionMilestoneExtra(_ item: InteractionMilestone) -> String {
        return substitutionPolicyBucket(item.netLoad())
    }
}
