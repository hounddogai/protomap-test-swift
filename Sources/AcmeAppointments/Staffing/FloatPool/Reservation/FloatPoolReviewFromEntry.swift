import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftEntriesForReview(_ items: [ShiftEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFloatPoolReviewsFromEntry(_ items: [ShiftEntry]) -> [FloatPoolReview] {
        var out: [FloatPoolReview] = []
        for item in items {
            let derived = newFloatPoolReview(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreFloatPoolReview(_ item: FloatPoolReview) -> String {
        return shiftScoreBucket(item.projectedValue())
    }
}
