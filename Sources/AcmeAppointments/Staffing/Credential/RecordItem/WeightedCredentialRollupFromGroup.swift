import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledShiftGroupsForRollup(_ items: [ScheduledShiftGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveWeightedCredentialRollupsFromGroup(_ items: [ScheduledShiftGroup]) -> [WeightedCredentialRollup] {
        var out: [WeightedCredentialRollup] = []
        for item in items {
            let derived = newWeightedCredentialRollup(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignWeightedCredentialRollup(_ item: WeightedCredentialRollup) -> Double {
        return globalShiftVarianceWeight(4, active: true)
    }
}
