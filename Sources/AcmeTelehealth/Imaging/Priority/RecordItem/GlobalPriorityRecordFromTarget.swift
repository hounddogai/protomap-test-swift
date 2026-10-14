import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyTargetsForRecord(_ items: [StudyTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveGlobalPriorityRecordsFromTarget(_ items: [StudyTarget]) -> [GlobalPriorityRecord] {
        var out: [GlobalPriorityRecord] = []
        for item in items {
            let derived = newGlobalPriorityRecord(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleGlobalPriorityRecord(_ item: GlobalPriorityRecord) -> Double {
        return lenientStudyRuleWeight(2, active: true)
    }
}
