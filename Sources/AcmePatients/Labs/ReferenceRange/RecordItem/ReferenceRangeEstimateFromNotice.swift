import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackAccessionNoticesForEstimate(_ items: [FallbackAccessionNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveReferenceRangeEstimatesFromNotice(_ items: [FallbackAccessionNotice]) -> [ReferenceRangeEstimate] {
        var out: [ReferenceRangeEstimate] = []
        for item in items {
            let derived = newReferenceRangeEstimate(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitReferenceRangeEstimate(_ item: ReferenceRangeEstimate) -> Double {
        return fallbackAccessionNoticeWeight(5, active: true)
    }
}
