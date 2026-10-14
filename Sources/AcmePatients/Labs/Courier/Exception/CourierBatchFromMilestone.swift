import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelMilestonesForBatch(_ items: [PanelMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCourierBatchesFromMilestone(_ items: [PanelMilestone]) -> [CourierBatch] {
        var out: [CourierBatch] = []
        for item in items {
            let derived = newCourierBatch(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeCourierBatch(_ item: CourierBatch) -> String {
        return normalizePanelThresholdCode(item.code)
    }
}
