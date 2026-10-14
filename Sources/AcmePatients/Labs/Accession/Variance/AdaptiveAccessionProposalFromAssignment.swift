import AcmePlatform
import Foundation

extension Labs {
    static func summarizeTieredSpecimenAssignmentsForProposal(_ items: [TieredSpecimenAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAdaptiveAccessionProposalsFromAssignment(_ items: [TieredSpecimenAssignment]) -> [AdaptiveAccessionProposal] {
        var out: [AdaptiveAccessionProposal] = []
        for item in items {
            let derived = newAdaptiveAccessionProposal(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveAdaptiveAccessionProposal(_ item: AdaptiveAccessionProposal) -> String {
        return normalizeBatchedSpecimenPolicyCode(item.code)
    }
}
