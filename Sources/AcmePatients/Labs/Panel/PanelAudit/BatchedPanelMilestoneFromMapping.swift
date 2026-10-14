import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalCourierMappingsForMilestone(_ items: [GlobalCourierMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveBatchedPanelMilestonesFromMapping(_ items: [GlobalCourierMapping]) -> [BatchedPanelMilestone] {
        var out: [BatchedPanelMilestone] = []
        for item in items {
            let derived = newBatchedPanelMilestone(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreBatchedPanelMilestone(_ item: BatchedPanelMilestone) -> Double {
        return globalCourierMappingWeight(3, active: true)
    }
}
