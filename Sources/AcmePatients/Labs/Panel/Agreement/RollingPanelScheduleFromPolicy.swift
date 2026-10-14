import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingResultPoliciesForSchedule(_ items: [PendingResultPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRollingPanelSchedulesFromPolicy(_ items: [PendingResultPolicy]) -> [RollingPanelSchedule] {
        var out: [RollingPanelSchedule] = []
        for item in items {
            let derived = newRollingPanelSchedule(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRollingPanelSchedule(_ item: RollingPanelSchedule) -> String {
        return cappedResultOverrideBucket(item.effectiveExposure())
    }
}
