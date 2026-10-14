import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAdaptiveAcuityPlanEstimatesForQuota(_ items: [AdaptiveAcuityPlanEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveRegionalFloatPoolQuotasFromEstimate(_ items: [AdaptiveAcuityPlanEstimate]) -> [RegionalFloatPoolQuota] {
        var out: [RegionalFloatPoolQuota] = []
        for item in items {
            let derived = newRegionalFloatPoolQuota(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignRegionalFloatPoolQuota(_ item: RegionalFloatPoolQuota) -> String {
        return classifyAcuityPlanMapping(item.projectedValue())
    }
}
