import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeStrictSlotAssignmentsForRequest(_ items: [StrictSlotAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveEligibilityRequestsFromAssignment(_ items: [StrictSlotAssignment]) -> [EligibilityRequest] {
        var out: [EligibilityRequest] = []
        for item in items {
            let derived = newEligibilityRequest(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateEligibilityRequest(_ item: EligibilityRequest) -> String {
        return primarySlotManifestBucket(item.measuredValue())
    }
}
