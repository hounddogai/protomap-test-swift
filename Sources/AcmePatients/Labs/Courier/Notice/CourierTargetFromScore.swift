import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingReferenceRangeScoresForTarget(_ items: [PendingReferenceRangeScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCourierTargetsFromScore(_ items: [PendingReferenceRangeScore]) -> [CourierTarget] {
        var out: [CourierTarget] = []
        for item in items {
            let derived = newCourierTarget(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateCourierTarget(_ item: CourierTarget) -> String {
        return classifyGlobalReferenceRangeSegment(item.weightedExposure())
    }
}
