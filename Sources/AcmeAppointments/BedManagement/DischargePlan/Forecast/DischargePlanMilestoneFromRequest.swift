import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientCleaningRequestsForMilestone(_ items: [LenientCleaningRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveDischargePlanMilestonesFromRequest(_ items: [LenientCleaningRequest]) -> [DischargePlanMilestone] {
        var out: [DischargePlanMilestone] = []
        for item in items {
            let derived = newDischargePlanMilestone(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyDischargePlanMilestone(_ item: DischargePlanMilestone) -> String {
        return normalizeAdaptiveCleaningNoticeCode(item.code)
    }
}
