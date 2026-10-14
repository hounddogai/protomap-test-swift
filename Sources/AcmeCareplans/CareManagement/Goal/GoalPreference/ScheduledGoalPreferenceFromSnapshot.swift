import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingGoalSnapshotsForPreference(_ items: [PendingGoalSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledGoalPreferencesFromSnapshot(_ items: [PendingGoalSnapshot]) -> [ScheduledGoalPreference] {
        var out: [ScheduledGoalPreference] = []
        for item in items {
            let derived = newScheduledGoalPreference(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeScheduledGoalPreference(_ item: ScheduledGoalPreference) -> Double {
        return pendingGoalSnapshotWeight(5, active: true)
    }
}
