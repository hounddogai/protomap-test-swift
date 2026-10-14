import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualBedBoardWindowsForTarget(_ items: [ManualBedBoardWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveTieredIsolationTargetsFromWindow(_ items: [ManualBedBoardWindow]) -> [TieredIsolationTarget] {
        var out: [TieredIsolationTarget] = []
        for item in items {
            let derived = newTieredIsolationTarget(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeTieredIsolationTarget(_ item: TieredIsolationTarget) -> Double {
        return bedBoardSummaryWeight(9, active: true)
    }
}
