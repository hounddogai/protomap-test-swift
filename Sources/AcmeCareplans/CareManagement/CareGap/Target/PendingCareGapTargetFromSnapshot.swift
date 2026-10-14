import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingGoalSnapshotsForTarget(_ items: [PendingGoalSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingCareGapTargetsFromSnapshot(_ items: [PendingGoalSnapshot]) -> [PendingCareGapTarget] {
        var out: [PendingCareGapTarget] = []
        for item in items {
            let derived = newPendingCareGapTarget(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPendingCareGapTarget(_ item: PendingCareGapTarget) -> String {
        return normalizePendingGoalSnapshotCode(item.code)
    }
}
