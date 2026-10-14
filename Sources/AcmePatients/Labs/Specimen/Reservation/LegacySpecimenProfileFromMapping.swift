import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRegionalReferenceRangeMappingsForProfile(_ items: [RegionalReferenceRangeMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLegacySpecimenProfilesFromMapping(_ items: [RegionalReferenceRangeMapping]) -> [LegacySpecimenProfile] {
        var out: [LegacySpecimenProfile] = []
        for item in items {
            let derived = newLegacySpecimenProfile(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitLegacySpecimenProfile(_ item: LegacySpecimenProfile) -> String {
        return classifyTieredReferenceRangeRecord(item.netExposure())
    }
}
