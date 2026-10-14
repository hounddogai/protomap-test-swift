import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredCareProtocolGroupsForMilestone(_ items: [TieredCareProtocolGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveSeasonalReadMilestonesFromGroup(_ items: [TieredCareProtocolGroup]) -> [SeasonalReadMilestone] {
        var out: [SeasonalReadMilestone] = []
        for item in items {
            let derived = newSeasonalReadMilestone(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileSeasonalReadMilestone(_ item: SeasonalReadMilestone) -> Double {
        return tieredCareProtocolGroupWeight(1, active: true)
    }
}
