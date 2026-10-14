import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningNoticesForCheckpoint(_ items: [CleaningNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRollingCensusCheckpointsFromNotice(_ items: [CleaningNotice]) -> [RollingCensusCheckpoint] {
        var out: [RollingCensusCheckpoint] = []
        for item in items {
            let derived = newRollingCensusCheckpoint(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateRollingCensusCheckpoint(_ item: RollingCensusCheckpoint) -> String {
        return cleaningNoticeBucket(item.weightedTotal())
    }
}
