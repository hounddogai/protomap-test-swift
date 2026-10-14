import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRegionalSubstitutionRollupsForRollup(_ items: [RegionalSubstitutionRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveLegacyFormularyRollupsFromRollup(_ items: [RegionalSubstitutionRollup]) -> [LegacyFormularyRollup] {
        var out: [LegacyFormularyRollup] = []
        for item in items {
            let derived = newLegacyFormularyRollup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchLegacyFormularyRollup(_ item: LegacyFormularyRollup) -> String {
        return normalizeSubstitutionGroupCode(item.code)
    }
}
