import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningQuotasForEstimate(_ items: [CleaningQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveDischargePlanEstimatesFromQuota(_ items: [CleaningQuota]) -> [DischargePlanEstimate] {
        var out: [DischargePlanEstimate] = []
        for item in items {
            let derived = newDischargePlanEstimate(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankDischargePlanEstimate(_ item: DischargePlanEstimate) -> String {
        return classifyCleaningQuota(item.projectedExposure())
    }
}
