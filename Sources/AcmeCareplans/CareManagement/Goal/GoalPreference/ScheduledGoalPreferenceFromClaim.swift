import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalProgramClaimsForPreference(_ items: [GlobalProgramClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveScheduledGoalPreferencesFromClaim(_ items: [GlobalProgramClaim]) -> [ScheduledGoalPreference] {
        var out: [ScheduledGoalPreference] = []
        for item in items {
            let derived = newScheduledGoalPreference(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitScheduledGoalPreference(_ item: ScheduledGoalPreference) -> String {
        return classifyBatchedProgramWindow(item.projectedValue())
    }
}
