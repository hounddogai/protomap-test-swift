import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingHandoffLedgersForSchedule(_ items: [PendingHandoffLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveCareProtocolSchedulesFromLedger(_ items: [PendingHandoffLedger]) -> [CareProtocolSchedule] {
        var out: [CareProtocolSchedule] = []
        for item in items {
            let derived = newCareProtocolSchedule(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateCareProtocolSchedule(_ item: CareProtocolSchedule) -> String {
        return handoffVarianceBucket(item.netTotal())
    }
}
