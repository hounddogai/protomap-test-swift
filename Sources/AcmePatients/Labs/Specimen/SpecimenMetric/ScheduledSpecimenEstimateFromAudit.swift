import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultAuditsForEstimate(_ items: [ResultAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveScheduledSpecimenEstimatesFromAudit(_ items: [ResultAudit]) -> [ScheduledSpecimenEstimate] {
        var out: [ScheduledSpecimenEstimate] = []
        for item in items {
            let derived = newScheduledSpecimenEstimate(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileScheduledSpecimenEstimate(_ item: ScheduledSpecimenEstimate) -> Double {
        return resultCycleWeight(3, active: true)
    }
}
