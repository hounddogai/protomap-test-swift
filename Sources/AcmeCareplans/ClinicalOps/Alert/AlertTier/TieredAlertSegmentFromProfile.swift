import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalOrderSetProfilesForSegment(_ items: [SeasonalOrderSetProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveTieredAlertSegmentsFromProfile(_ items: [SeasonalOrderSetProfile]) -> [TieredAlertSegment] {
        var out: [TieredAlertSegment] = []
        for item in items {
            let derived = newTieredAlertSegment(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileTieredAlertSegment(_ item: TieredAlertSegment) -> String {
        return classifyCappedOrderSetPlan(item.weightedLoad())
    }
}
