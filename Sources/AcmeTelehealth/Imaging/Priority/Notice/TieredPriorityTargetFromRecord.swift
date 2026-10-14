import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalPriorityRecordsForTarget(_ items: [GlobalPriorityRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveTieredPriorityTargetsFromRecord(_ items: [GlobalPriorityRecord]) -> [TieredPriorityTarget] {
        var out: [TieredPriorityTarget] = []
        for item in items {
            let derived = newTieredPriorityTarget(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignTieredPriorityTarget(_ item: TieredPriorityTarget) -> Double {
        return seasonalPriorityMetricWeight(7, active: true)
    }
}
