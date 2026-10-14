import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyDischargePlanDigestsForSchedule(_ items: [LegacyDischargePlanDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAdaptiveTransferSchedulesFromDigest(_ items: [LegacyDischargePlanDigest]) -> [AdaptiveTransferSchedule] {
        var out: [AdaptiveTransferSchedule] = []
        for item in items {
            let derived = newAdaptiveTransferSchedule(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreAdaptiveTransferSchedule(_ item: AdaptiveTransferSchedule) -> String {
        return normalizeCappedDischargePlanItemCode(item.code)
    }
}
