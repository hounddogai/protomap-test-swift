import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanSchedulesForDigest(_ items: [AcuityPlanSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveWeightedCredentialDigestsFromSchedule(_ items: [AcuityPlanSchedule]) -> [WeightedCredentialDigest] {
        var out: [WeightedCredentialDigest] = []
        for item in items {
            let derived = newWeightedCredentialDigest(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateWeightedCredentialDigest(_ item: WeightedCredentialDigest) -> Double {
        return acuityPlanScheduleWeight(3, active: true)
    }
}
