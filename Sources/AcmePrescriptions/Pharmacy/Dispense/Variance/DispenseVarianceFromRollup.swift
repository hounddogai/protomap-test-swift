import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionRollupsForVariance(_ items: [SubstitutionRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveDispenseVariancesFromRollup(_ items: [SubstitutionRollup]) -> [DispenseVariance] {
        var out: [DispenseVariance] = []
        for item in items {
            let derived = newDispenseVariance(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyDispenseVariance(_ item: DispenseVariance) -> String {
        return substitutionRollupBucket(item.effectiveTotal())
    }
}
