import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeManualHandoffSchedulesForProposal(_ items: [ManualHandoffSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveDefaultTaskProposalsFromSchedule(_ items: [ManualHandoffSchedule]) -> [DefaultTaskProposal] {
        var out: [DefaultTaskProposal] = []
        for item in items {
            let derived = newDefaultTaskProposal(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceDefaultTaskProposal(_ item: DefaultTaskProposal) -> String {
        return handoffBudgetBucket(item.weightedTotal())
    }
}
