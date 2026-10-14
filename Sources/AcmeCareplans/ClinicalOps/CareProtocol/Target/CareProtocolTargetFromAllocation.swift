import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskAllocationsForTarget(_ items: [TaskAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCareProtocolTargetsFromAllocation(_ items: [TaskAllocation]) -> [CareProtocolTarget] {
        var out: [CareProtocolTarget] = []
        for item in items {
            let derived = newCareProtocolTarget(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveCareProtocolTarget(_ item: CareProtocolTarget) -> String {
        return taskAllocationBucket(item.weightedVolume())
    }
}
