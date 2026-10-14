import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryReferralExceptionsForAssignment(_ items: [PrimaryReferralException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryClosureAssignmentsFromException(_ items: [PrimaryReferralException]) -> [PrimaryClosureAssignment] {
        var out: [PrimaryClosureAssignment] = []
        for item in items {
            let derived = newPrimaryClosureAssignment(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocatePrimaryClosureAssignment(_ item: PrimaryClosureAssignment) -> String {
        return primaryReferralExceptionBucket(item.weightedTotal())
    }
}
