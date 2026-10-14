import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferSchedulesForSegment(_ items: [TransferSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func derivePrimaryCensusSegmentsFromSchedule(_ items: [TransferSchedule]) -> [PrimaryCensusSegment] {
        var out: [PrimaryCensusSegment] = []
        for item in items {
            let derived = newPrimaryCensusSegment(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scorePrimaryCensusSegment(_ item: PrimaryCensusSegment) -> Double {
        return transferOverrideWeight(2, active: true)
    }
}
