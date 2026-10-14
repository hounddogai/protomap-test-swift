import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLegacySpecimenNoticesForDigest(_ items: [LegacySpecimenNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRegionalResultDigestsFromNotice(_ items: [LegacySpecimenNotice]) -> [RegionalResultDigest] {
        var out: [RegionalResultDigest] = []
        for item in items {
            let derived = newRegionalResultDigest(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRegionalResultDigest(_ item: RegionalResultDigest) -> Double {
        return primarySpecimenMetricWeight(8, active: true)
    }
}
