import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingStudySegmentsForSnapshot(_ items: [RollingStudySegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWorklistSnapshotsFromSegment(_ items: [RollingStudySegment]) -> [WorklistSnapshot] {
        var out: [WorklistSnapshot] = []
        for item in items {
            let derived = newWorklistSnapshot(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignWorklistSnapshot(_ item: WorklistSnapshot) -> String {
        return rollingStudySegmentBucket(item.projectedValue())
    }
}
