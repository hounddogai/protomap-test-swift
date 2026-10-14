import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalCareProtocolAssignmentsForReview(_ items: [GlobalCareProtocolAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveCareProtocolReviewsFromAssignment(_ items: [GlobalCareProtocolAssignment]) -> [CareProtocolReview] {
        var out: [CareProtocolReview] = []
        for item in items {
            let derived = newCareProtocolReview(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveCareProtocolReview(_ item: CareProtocolReview) -> String {
        return globalCareProtocolAssignmentBucket(item.measuredValue())
    }
}
