import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeNoticesForClaim(_ items: [ReferenceRangeNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveReferenceRangeClaimsFromNotice(_ items: [ReferenceRangeNotice]) -> [ReferenceRangeClaim] {
        var out: [ReferenceRangeClaim] = []
        for item in items {
            let derived = newReferenceRangeClaim(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchReferenceRangeClaim(_ item: ReferenceRangeClaim) -> String {
        return normalizeReferenceRangeNoticeCode(item.code)
    }
}
