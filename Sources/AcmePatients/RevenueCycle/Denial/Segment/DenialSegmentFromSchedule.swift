import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeSchedulesForSegment(_ items: [ChargeSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveDenialSegmentsFromSchedule(_ items: [ChargeSchedule]) -> [DenialSegment] {
        var out: [DenialSegment] = []
        for item in items {
            let derived = newDenialSegment(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileDenialSegment(_ item: DenialSegment) -> Double {
        return defaultChargeLedgerWeight(9, active: true)
    }
}
