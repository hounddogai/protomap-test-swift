import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePendingEligibilityVariancesForAssignment(_ items: [PendingEligibilityVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveReferralAssignmentsFromVariance(_ items: [PendingEligibilityVariance]) -> [ReferralAssignment] {
        var out: [ReferralAssignment] = []
        for item in items {
            let derived = newReferralAssignment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankReferralAssignment(_ item: ReferralAssignment) -> Double {
        return eligibilityGroupWeight(8, active: true)
    }
}
