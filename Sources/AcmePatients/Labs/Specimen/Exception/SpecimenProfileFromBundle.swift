import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeBundlesForProfile(_ items: [ReferenceRangeBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSpecimenProfilesFromBundle(_ items: [ReferenceRangeBundle]) -> [SpecimenProfile] {
        var out: [SpecimenProfile] = []
        for item in items {
            let derived = newSpecimenProfile(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignSpecimenProfile(_ item: SpecimenProfile) -> String {
        return referenceRangeRollupBucket(item.effectiveLoad())
    }
}
