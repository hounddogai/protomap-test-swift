import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDefaultDischargePlanWindowsForGroup(_ items: [DefaultDischargePlanWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveBedBoardGroupsFromWindow(_ items: [DefaultDischargePlanWindow]) -> [AdaptiveBedBoardGroup] {
        var out: [AdaptiveBedBoardGroup] = []
        for item in items {
            let derived = newAdaptiveBedBoardGroup(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planAdaptiveBedBoardGroup(_ item: AdaptiveBedBoardGroup) -> String {
        return defaultDischargePlanWindowBucket(item.adjustedVolume())
    }
}
