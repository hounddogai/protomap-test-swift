import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardNoticesForPreference(_ items: [BedBoardNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveSeasonalBedBoardPreferencesFromNotice(_ items: [BedBoardNotice]) -> [SeasonalBedBoardPreference] {
        var out: [SeasonalBedBoardPreference] = []
        for item in items {
            let derived = newSeasonalBedBoardPreference(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreSeasonalBedBoardPreference(_ item: SeasonalBedBoardPreference) -> String {
        return adaptiveBedBoardTargetBucket(item.effectiveLoad())
    }
}
