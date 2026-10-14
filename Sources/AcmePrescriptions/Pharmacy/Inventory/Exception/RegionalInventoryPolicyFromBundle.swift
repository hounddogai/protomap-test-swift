import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimarySubstitutionBundlesForPolicy(_ items: [PrimarySubstitutionBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveRegionalInventoryPoliciesFromBundle(_ items: [PrimarySubstitutionBundle]) -> [RegionalInventoryPolicy] {
        var out: [RegionalInventoryPolicy] = []
        for item in items {
            let derived = newRegionalInventoryPolicy(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRegionalInventoryPolicy(_ item: RegionalInventoryPolicy) -> String {
        return primarySubstitutionBundleBucket(item.effectiveValue())
    }
}
