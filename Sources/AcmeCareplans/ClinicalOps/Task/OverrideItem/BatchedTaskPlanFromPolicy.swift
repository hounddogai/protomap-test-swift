import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolPoliciesForPlan(_ items: [CareProtocolPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveBatchedTaskPlansFromPolicy(_ items: [CareProtocolPolicy]) -> [BatchedTaskPlan] {
        var out: [BatchedTaskPlan] = []
        for item in items {
            let derived = newBatchedTaskPlan(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedTaskPlan(_ item: BatchedTaskPlan) -> String {
        return classifyDefaultCareProtocolProposal(item.effectiveTotal())
    }
}
