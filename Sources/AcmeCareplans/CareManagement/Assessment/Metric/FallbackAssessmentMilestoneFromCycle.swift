import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCappedProgramCyclesForMilestone(_ items: [CappedProgramCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFallbackAssessmentMilestonesFromCycle(_ items: [CappedProgramCycle]) -> [FallbackAssessmentMilestone] {
        var out: [FallbackAssessmentMilestone] = []
        for item in items {
            let derived = newFallbackAssessmentMilestone(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleFallbackAssessmentMilestone(_ item: FallbackAssessmentMilestone) -> Double {
        return cappedProgramCycleWeight(1, active: true)
    }
}
