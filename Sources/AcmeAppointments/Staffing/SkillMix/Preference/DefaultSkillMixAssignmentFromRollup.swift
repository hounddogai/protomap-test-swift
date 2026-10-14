import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeWeightedCredentialRollupsForAssignment(_ items: [WeightedCredentialRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveDefaultSkillMixAssignmentsFromRollup(_ items: [WeightedCredentialRollup]) -> [DefaultSkillMixAssignment] {
        var out: [DefaultSkillMixAssignment] = []
        for item in items {
            let derived = newDefaultSkillMixAssignment(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateDefaultSkillMixAssignment(_ item: DefaultSkillMixAssignment) -> String {
        return weightedCredentialRollupBucket(item.weightedVolume())
    }
}
