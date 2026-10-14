import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeFallbackWorklistCheckpointsForEstimate(_ items: [FallbackWorklistCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveManualReadEstimatesFromCheckpoint(_ items: [FallbackWorklistCheckpoint]) -> [ManualReadEstimate] {
        var out: [ManualReadEstimate] = []
        for item in items {
            let derived = newManualReadEstimate(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateManualReadEstimate(_ item: ManualReadEstimate) -> String {
        return worklistSnapshotBucket(item.measuredValue())
    }
}
