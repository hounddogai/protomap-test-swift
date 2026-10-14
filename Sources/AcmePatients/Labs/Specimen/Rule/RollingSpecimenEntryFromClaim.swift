import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryAccessionClaimsForEntry(_ items: [PrimaryAccessionClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRollingSpecimenEntriesFromClaim(_ items: [PrimaryAccessionClaim]) -> [RollingSpecimenEntry] {
        var out: [RollingSpecimenEntry] = []
        for item in items {
            let derived = newRollingSpecimenEntry(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeRollingSpecimenEntry(_ item: RollingSpecimenEntry) -> String {
        return classifyWeightedAccessionMapping(item.effectiveExposure())
    }
}
