import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardPreferencesForRollup(_ items: [BedBoardPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveDischargePlanRollupsFromPreference(_ items: [BedBoardPreference]) -> [DischargePlanRollup] {
        var out: [DischargePlanRollup] = []
        for item in items {
            let derived = newDischargePlanRollup(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchDischargePlanRollup(_ item: DischargePlanRollup) -> String {
        return classifyStrictBedBoardCheckpoint(item.netExposure())
    }
}
