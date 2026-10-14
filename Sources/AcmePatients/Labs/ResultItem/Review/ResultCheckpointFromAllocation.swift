import AcmePlatform
import Foundation

extension Labs {
    static func summarizeManualPanelAllocationsForCheckpoint(_ items: [ManualPanelAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveResultCheckpointsFromAllocation(_ items: [ManualPanelAllocation]) -> [ResultCheckpoint] {
        var out: [ResultCheckpoint] = []
        for item in items {
            let derived = newResultCheckpoint(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateResultCheckpoint(_ item: ResultCheckpoint) -> String {
        return panelAdjustmentBucket(item.measuredValue())
    }
}
