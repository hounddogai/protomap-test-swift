import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingTaskProposalsForDraft(_ items: [PendingTaskProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultHandoffDraftsFromProposal(_ items: [PendingTaskProposal]) -> [DefaultHandoffDraft] {
        var out: [DefaultHandoffDraft] = []
        for item in items {
            let derived = newDefaultHandoffDraft(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyDefaultHandoffDraft(_ item: DefaultHandoffDraft) -> String {
        return pendingTaskProposalBucket(item.effectiveLoad())
    }
}
