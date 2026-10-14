import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingTaskProposalsForWindow(_ items: [PendingTaskProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyTaskWindowsFromProposal(_ items: [PendingTaskProposal]) -> [LegacyTaskWindow] {
        var out: [LegacyTaskWindow] = []
        for item in items {
            let derived = newLegacyTaskWindow(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateLegacyTaskWindow(_ item: LegacyTaskWindow) -> String {
        return pendingTaskProposalBucket(item.measuredValue())
    }
}
