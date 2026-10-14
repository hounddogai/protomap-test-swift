import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationSchedulesForCheckpoint(_ items: [IsolationSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRollingCensusCheckpointsFromSchedule(_ items: [IsolationSchedule]) -> [RollingCensusCheckpoint] {
        var out: [RollingCensusCheckpoint] = []
        for item in items {
            let derived = newRollingCensusCheckpoint(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRollingCensusCheckpoint(_ item: RollingCensusCheckpoint) -> String {
        return normalizeManualIsolationSegmentCode(item.code)
    }
}
