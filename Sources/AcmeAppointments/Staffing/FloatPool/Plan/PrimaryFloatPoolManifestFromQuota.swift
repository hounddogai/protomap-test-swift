import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalFloatPoolQuotasForManifestPlan(_ items: [RegionalFloatPoolQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePrimaryFloatPoolManifestsFromQuota(_ items: [RegionalFloatPoolQuota]) -> [PrimaryFloatPoolManifest] {
        var out: [PrimaryFloatPoolManifest] = []
        for item in items {
            let derived = newPrimaryFloatPoolManifest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergePrimaryFloatPoolManifest(_ item: PrimaryFloatPoolManifest) -> Double {
        return regionalFloatPoolQuotaWeight(3, active: true)
    }
}
