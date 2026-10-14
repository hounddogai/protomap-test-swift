import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBatchedIsolationRollupsForWindow(_ items: [BatchedIsolationRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveBatchedIsolationWindowsFromRollup(_ items: [BatchedIsolationRollup]) -> [BatchedIsolationWindow] {
        var out: [BatchedIsolationWindow] = []
        for item in items {
            let derived = newBatchedIsolationWindow(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeBatchedIsolationWindow(_ item: BatchedIsolationWindow) -> Double {
        return rollingIsolationPreferenceWeight(8, active: true)
    }
}
