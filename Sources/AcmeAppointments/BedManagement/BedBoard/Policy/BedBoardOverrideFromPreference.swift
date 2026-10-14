import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusPreferencesForOverride(_ items: [CensusPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBedBoardOverridesFromPreference(_ items: [CensusPreference]) -> [BedBoardOverride] {
        var out: [BedBoardOverride] = []
        for item in items {
            let derived = newBedBoardOverride(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankBedBoardOverride(_ item: BedBoardOverride) -> String {
        return censusRuleBucket(item.effectiveExposure())
    }
}
