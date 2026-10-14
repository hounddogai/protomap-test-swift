import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityScoresForMappingMapping(_ items: [PriorityScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveScheduledCareProtocolMappingsFromScore(_ items: [PriorityScore]) -> [ScheduledCareProtocolMapping] {
        var out: [ScheduledCareProtocolMapping] = []
        for item in items {
            let derived = newScheduledCareProtocolMapping(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceScheduledCareProtocolMapping(_ item: ScheduledCareProtocolMapping) -> String {
        return priorityRecordBucket(item.measuredValue())
    }
}
