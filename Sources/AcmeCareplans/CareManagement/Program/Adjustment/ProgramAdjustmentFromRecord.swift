import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeScheduledRiskScoreRecordsForAdjustment(_ items: [ScheduledRiskScoreRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveProgramAdjustmentsFromRecord(_ items: [ScheduledRiskScoreRecord]) -> [ProgramAdjustment] {
        var out: [ProgramAdjustment] = []
        for item in items {
            let derived = newProgramAdjustment(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectProgramAdjustment(_ item: ProgramAdjustment) -> String {
        return scheduledRiskScoreRecordBucket(item.measuredValue())
    }
}
