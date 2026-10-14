import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingPriorityMetricsForSlot(_ items: [PendingPriorityMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveCappedStudySlotsFromMetric(_ items: [PendingPriorityMetric]) -> [CappedStudySlot] {
        var out: [CappedStudySlot] = []
        for item in items {
            let derived = newCappedStudySlot(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveCappedStudySlot(_ item: CappedStudySlot) -> String {
        return normalizeGlobalPriorityRecordCode(item.code)
    }
}
