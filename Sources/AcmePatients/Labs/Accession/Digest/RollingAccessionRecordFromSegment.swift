import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeSegmentsForRecord(_ items: [ReferenceRangeSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRollingAccessionRecordsFromSegment(_ items: [ReferenceRangeSegment]) -> [RollingAccessionRecord] {
        var out: [RollingAccessionRecord] = []
        for item in items {
            let derived = newRollingAccessionRecord(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRollingAccessionRecord(_ item: RollingAccessionRecord) -> String {
        return classifyReferenceRangeRule(item.adjustedLoad())
    }
}
