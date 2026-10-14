import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskVariancesForCheckpoint(_ items: [TaskVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedCareProtocolCheckpointsFromVariance(_ items: [TaskVariance]) -> [CappedCareProtocolCheckpoint] {
        var out: [CappedCareProtocolCheckpoint] = []
        for item in items {
            let derived = newCappedCareProtocolCheckpoint(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCappedCareProtocolCheckpoint(_ item: CappedCareProtocolCheckpoint) -> String {
        return classifyTaskPlan(item.effectiveLoad())
    }
}
