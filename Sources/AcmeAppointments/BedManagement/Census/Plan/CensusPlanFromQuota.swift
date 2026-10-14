import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningQuotasForPlan(_ items: [CleaningQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveCensusPlansFromQuota(_ items: [CleaningQuota]) -> [CensusPlan] {
        var out: [CensusPlan] = []
        for item in items {
            let derived = newCensusPlan(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreCensusPlan(_ item: CensusPlan) -> Double {
        return cleaningPlanWeight(3, active: true)
    }
}
