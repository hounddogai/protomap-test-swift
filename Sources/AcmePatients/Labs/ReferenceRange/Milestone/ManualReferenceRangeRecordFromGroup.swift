import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultGroupsForRecord(_ items: [ResultGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveManualReferenceRangeRecordsFromGroup(_ items: [ResultGroup]) -> [ManualReferenceRangeRecord] {
        var out: [ManualReferenceRangeRecord] = []
        for item in items {
            let derived = newManualReferenceRangeRecord(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchManualReferenceRangeRecord(_ item: ManualReferenceRangeRecord) -> Double {
        return resultGroupWeight(6, active: true)
    }
}
