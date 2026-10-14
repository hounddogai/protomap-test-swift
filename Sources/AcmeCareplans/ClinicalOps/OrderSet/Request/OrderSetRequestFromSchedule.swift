import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalRoundingSchedulesForRequest(_ items: [GlobalRoundingSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveOrderSetRequestsFromSchedule(_ items: [GlobalRoundingSchedule]) -> [OrderSetRequest] {
        var out: [OrderSetRequest] = []
        for item in items {
            let derived = newOrderSetRequest(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectOrderSetRequest(_ item: OrderSetRequest) -> Double {
        return batchedRoundingSlotWeight(3, active: true)
    }
}
