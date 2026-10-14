import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeScheduledTransferProfilesForTarget(_ items: [ScheduledTransferProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackCensusTargetsFromProfile(_ items: [ScheduledTransferProfile]) -> [FallbackCensusTarget] {
        var out: [FallbackCensusTarget] = []
        for item in items {
            let derived = newFallbackCensusTarget(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileFallbackCensusTarget(_ item: FallbackCensusTarget) -> Double {
        return pendingTransferNoticeWeight(8, active: true)
    }
}
