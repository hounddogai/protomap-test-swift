import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolSchedulesForAdjustment(_ items: [CareProtocolSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveHandoffAdjustmentsFromSchedule(_ items: [CareProtocolSchedule]) -> [HandoffAdjustment] {
        var out: [HandoffAdjustment] = []
        for item in items {
            let derived = newHandoffAdjustment(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitHandoffAdjustment(_ item: HandoffAdjustment) -> String {
        return careProtocolScheduleBucket(item.measuredValue())
    }
}
