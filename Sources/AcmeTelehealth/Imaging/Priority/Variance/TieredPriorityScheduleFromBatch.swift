import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalCareProtocolBatchesForSchedule(_ items: [GlobalCareProtocolBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveTieredPrioritySchedulesFromBatch(_ items: [GlobalCareProtocolBatch]) -> [TieredPrioritySchedule] {
        var out: [TieredPrioritySchedule] = []
        for item in items {
            let derived = newTieredPrioritySchedule(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeTieredPrioritySchedule(_ item: TieredPrioritySchedule) -> Double {
        return globalCareProtocolBatchWeight(5, active: true)
    }
}
