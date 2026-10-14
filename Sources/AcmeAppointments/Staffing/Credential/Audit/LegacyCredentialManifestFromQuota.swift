import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalFloatPoolQuotasForManifest(_ items: [RegionalFloatPoolQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveLegacyCredentialManifestsFromQuota(_ items: [RegionalFloatPoolQuota]) -> [LegacyCredentialManifest] {
        var out: [LegacyCredentialManifest] = []
        for item in items {
            let derived = newLegacyCredentialManifest(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLegacyCredentialManifest(_ item: LegacyCredentialManifest) -> Double {
        return floatPoolEntryWeight(3, active: true)
    }
}
