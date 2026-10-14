import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardWindowsForProfile(_ items: [BedBoardWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveDischargePlanProfilesFromWindow(_ items: [BedBoardWindow]) -> [DischargePlanProfile] {
        var out: [DischargePlanProfile] = []
        for item in items {
            let derived = newDischargePlanProfile(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeDischargePlanProfile(_ item: DischargePlanProfile) -> String {
        return bedBoardScoreBucket(item.adjustedLoad())
    }
}
