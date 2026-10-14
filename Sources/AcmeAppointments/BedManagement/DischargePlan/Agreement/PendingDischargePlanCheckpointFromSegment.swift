import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDefaultIsolationSegmentsForCheckpoint(_ items: [DefaultIsolationSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePendingDischargePlanCheckpointsFromSegment(_ items: [DefaultIsolationSegment]) -> [PendingDischargePlanCheckpoint] {
        var out: [PendingDischargePlanCheckpoint] = []
        for item in items {
            let derived = newPendingDischargePlanCheckpoint(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPendingDischargePlanCheckpoint(_ item: PendingDischargePlanCheckpoint) -> String {
        return pendingIsolationExceptionBucket(item.effectiveExposure())
    }
}
