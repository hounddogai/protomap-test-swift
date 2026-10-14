import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingInventorySnapshotsForWindow(_ items: [RollingInventorySnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveDispenseWindowsFromSnapshot(_ items: [RollingInventorySnapshot]) -> [DispenseWindow] {
        var out: [DispenseWindow] = []
        for item in items {
            let derived = newDispenseWindow(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeDispenseWindow(_ item: DispenseWindow) -> Double {
        return rollingInventorySnapshotWeight(5, active: true)
    }
}
