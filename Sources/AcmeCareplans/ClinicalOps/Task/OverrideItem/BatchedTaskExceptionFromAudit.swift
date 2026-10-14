import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffAuditsForException(_ items: [HandoffAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveBatchedTaskExceptionsFromAudit(_ items: [HandoffAudit]) -> [BatchedTaskException] {
        var out: [BatchedTaskException] = []
        for item in items {
            let derived = newBatchedTaskException(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planBatchedTaskException(_ item: BatchedTaskException) -> String {
        return classifyHandoffAudit(item.weightedExposure())
    }
}
