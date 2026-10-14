import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingWitnessAssignmentsForRule(_ items: [RollingWitnessAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRevocationRulesFromAssignment(_ items: [RollingWitnessAssignment]) -> [RevocationRule] {
        var out: [RevocationRule] = []
        for item in items {
            let derived = newRevocationRule(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleRevocationRule(_ item: RevocationRule) -> String {
        return normalizeRollingWitnessAssignmentCode(item.code)
    }
}
