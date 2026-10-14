import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRollingReferenceRangeRollupsForNotice(_ items: [RollingReferenceRangeRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveFallbackAccessionNoticesFromRollup(_ items: [RollingReferenceRangeRollup]) -> [FallbackAccessionNotice] {
        var out: [FallbackAccessionNotice] = []
        for item in items {
            let derived = newFallbackAccessionNotice(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleFallbackAccessionNotice(_ item: FallbackAccessionNotice) -> String {
        return referenceRangeRequestBucket(item.measuredValue())
    }
}
