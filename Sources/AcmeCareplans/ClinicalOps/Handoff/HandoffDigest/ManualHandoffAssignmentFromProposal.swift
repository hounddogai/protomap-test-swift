import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyOrderSetProposalsForAssignment(_ items: [LegacyOrderSetProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveManualHandoffAssignmentsFromProposal(_ items: [LegacyOrderSetProposal]) -> [ManualHandoffAssignment] {
        var out: [ManualHandoffAssignment] = []
        for item in items {
            let derived = newManualHandoffAssignment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeManualHandoffAssignment(_ item: ManualHandoffAssignment) -> String {
        return orderSetScheduleBucket(item.measuredValue())
    }
}
