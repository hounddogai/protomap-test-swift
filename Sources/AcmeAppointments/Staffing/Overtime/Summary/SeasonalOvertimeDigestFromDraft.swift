import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeManualAcuityPlanDraftsForDigest(_ items: [ManualAcuityPlanDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveSeasonalOvertimeDigestsFromDraft(_ items: [ManualAcuityPlanDraft]) -> [SeasonalOvertimeDigest] {
        var out: [SeasonalOvertimeDigest] = []
        for item in items {
            let derived = newSeasonalOvertimeDigest(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitSeasonalOvertimeDigest(_ item: SeasonalOvertimeDigest) -> String {
        return acuityPlanItemBucket(item.measuredValue())
    }
}
