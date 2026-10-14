import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertAssignmentsForProposal(_ items: [AlertAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveTaskProposalsFromAssignment(_ items: [AlertAssignment]) -> [TaskProposal] {
        var out: [TaskProposal] = []
        for item in items {
            let derived = newTaskProposal(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyTaskProposal(_ item: TaskProposal) -> String {
        return normalizeAlertBatchCode(item.code)
    }
}
