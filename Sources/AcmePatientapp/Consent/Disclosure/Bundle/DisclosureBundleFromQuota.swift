import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationQuotasForBundle(_ items: [RevocationQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveDisclosureBundlesFromQuota(_ items: [RevocationQuota]) -> [DisclosureBundle] {
        var out: [DisclosureBundle] = []
        for item in items {
            let derived = newDisclosureBundle(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeDisclosureBundle(_ item: DisclosureBundle) -> Double {
        return regionalRevocationEstimateWeight(7, active: true)
    }
}
