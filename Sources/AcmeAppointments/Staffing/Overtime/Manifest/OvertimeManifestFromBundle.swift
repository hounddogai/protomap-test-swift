import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalAcuityPlanBundlesForManifest(_ items: [SeasonalAcuityPlanBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveOvertimeManifestsFromBundle(_ items: [SeasonalAcuityPlanBundle]) -> [OvertimeManifest] {
        var out: [OvertimeManifest] = []
        for item in items {
            let derived = newOvertimeManifest(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planOvertimeManifest(_ item: OvertimeManifest) -> String {
        return classifySeasonalAcuityPlanBundle(item.weightedTotal())
    }
}
