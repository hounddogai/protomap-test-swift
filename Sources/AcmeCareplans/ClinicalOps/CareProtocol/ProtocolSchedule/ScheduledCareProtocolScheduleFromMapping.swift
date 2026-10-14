import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeBatchedRoundingMappingsForSchedule(_ items: [BatchedRoundingMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledCareProtocolSchedulesFromMapping(_ items: [BatchedRoundingMapping]) -> [ScheduledCareProtocolSchedule] {
        var out: [ScheduledCareProtocolSchedule] = []
        for item in items {
            let derived = newScheduledCareProtocolSchedule(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveScheduledCareProtocolSchedule(_ item: ScheduledCareProtocolSchedule) -> String {
        return classifyBatchedRoundingMapping(item.measuredValue())
    }
}
