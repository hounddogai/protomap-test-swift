import AcmePlatform
import Foundation

extension Labs {
    static func summarizeBatchedAccessionEstimatesForCycle(_ items: [BatchedAccessionEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedResultCyclesFromEstimate(_ items: [BatchedAccessionEstimate]) -> [CappedResultCycle] {
        var out: [CappedResultCycle] = []
        for item in items {
            let derived = newCappedResultCycle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveCappedResultCycle(_ item: CappedResultCycle) -> String {
        return normalizeAccessionSnapshotCode(item.code)
    }
}
