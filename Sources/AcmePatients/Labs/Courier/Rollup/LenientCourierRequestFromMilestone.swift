import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingCourierMilestonesForRequest(_ items: [PendingCourierMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveLenientCourierRequestsFromMilestone(_ items: [PendingCourierMilestone]) -> [LenientCourierRequest] {
        var out: [LenientCourierRequest] = []
        for item in items {
            let derived = newLenientCourierRequest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLenientCourierRequest(_ item: LenientCourierRequest) -> Double {
        return courierRollupWeight(1, active: true)
    }
}
