import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetMilestonesForException(_ items: [OrderSetMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveCareProtocolExceptionsFromMilestone(_ items: [OrderSetMilestone]) -> [CareProtocolException] {
        var out: [CareProtocolException] = []
        for item in items {
            let derived = newCareProtocolException(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitCareProtocolException(_ item: CareProtocolException) -> String {
        return orderSetMilestoneBucket(item.measuredValue())
    }
}
