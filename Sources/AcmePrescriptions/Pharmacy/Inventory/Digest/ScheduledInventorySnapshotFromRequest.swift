import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRegionalRecallRequestsForSnapshot(_ items: [RegionalRecallRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveScheduledInventorySnapshotsFromRequest(_ items: [RegionalRecallRequest]) -> [ScheduledInventorySnapshot] {
        var out: [ScheduledInventorySnapshot] = []
        for item in items {
            let derived = newScheduledInventorySnapshot(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyScheduledInventorySnapshotExtra(_ item: ScheduledInventorySnapshot) -> String {
        return classifyRegionalRecallRequest(item.weightedLoad())
    }
}
