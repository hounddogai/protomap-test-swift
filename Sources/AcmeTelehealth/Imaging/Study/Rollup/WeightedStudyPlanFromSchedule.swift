import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeScheduledCareProtocolSchedulesForPlan(_ items: [ScheduledCareProtocolSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveWeightedStudyPlansFromSchedule(_ items: [ScheduledCareProtocolSchedule]) -> [WeightedStudyPlan] {
        var out: [WeightedStudyPlan] = []
        for item in items {
            let derived = newWeightedStudyPlan(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWeightedStudyPlan(_ item: WeightedStudyPlan) -> String {
        return cappedCareProtocolPreferenceBucket(item.weightedVolume())
    }
}
