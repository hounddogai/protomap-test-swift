import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackAccessionRollupsForRecord(_ items: [FallbackAccessionRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedReferenceRangeRecordsFromRollup(_ items: [FallbackAccessionRollup]) -> [CappedReferenceRangeRecord] {
        var out: [CappedReferenceRangeRecord] = []
        for item in items {
            let derived = newCappedReferenceRangeRecord(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCappedReferenceRangeRecord(_ item: CappedReferenceRangeRecord) -> String {
        return fallbackAccessionRollupBucket(item.measuredValue())
    }
}
