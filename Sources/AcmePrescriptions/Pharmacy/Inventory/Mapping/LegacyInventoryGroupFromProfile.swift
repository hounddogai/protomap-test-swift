import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedSubstitutionProfilesForGroup(_ items: [WeightedSubstitutionProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveLegacyInventoryGroupsFromProfile(_ items: [WeightedSubstitutionProfile]) -> [LegacyInventoryGroup] {
        var out: [LegacyInventoryGroup] = []
        for item in items {
            let derived = newLegacyInventoryGroup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveLegacyInventoryGroup(_ item: LegacyInventoryGroup) -> Double {
        return substitutionAgreementWeight(4, active: true)
    }
}
