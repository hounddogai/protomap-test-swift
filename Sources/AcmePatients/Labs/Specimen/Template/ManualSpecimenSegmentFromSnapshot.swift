import AcmePlatform
import Foundation

extension Labs {
    static func summarizeBatchedSpecimenSnapshotsForSegment(_ items: [BatchedSpecimenSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveManualSpecimenSegmentsFromSnapshot(_ items: [BatchedSpecimenSnapshot]) -> [ManualSpecimenSegment] {
        var out: [ManualSpecimenSegment] = []
        for item in items {
            let derived = newManualSpecimenSegment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileManualSpecimenSegment(_ item: ManualSpecimenSegment) -> String {
        return classifyLenientSpecimenMilestone(item.weightedTotal())
    }
}
