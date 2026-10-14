import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBatchedCleaningRecordsForBaseline(_ items: [BatchedCleaningRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func derivePrimaryDischargePlanBaselinesFromRecord(_ items: [BatchedCleaningRecord]) -> [PrimaryDischargePlanBaseline] {
        var out: [PrimaryDischargePlanBaseline] = []
        for item in items {
            let derived = newPrimaryDischargePlanBaseline(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planPrimaryDischargePlanBaseline(_ item: PrimaryDischargePlanBaseline) -> String {
        return manualCleaningAssignmentBucket(item.projectedVolume())
    }
}
