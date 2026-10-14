import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLegacyReferralAssignmentsForRequest(_ items: [LegacyReferralAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveReferralRequestsFromAssignment(_ items: [LegacyReferralAssignment]) -> [ReferralRequest] {
        var out: [ReferralRequest] = []
        for item in items {
            let derived = newReferralRequest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceReferralRequest(_ item: ReferralRequest) -> String {
        return classifySeasonalReferralProfile(item.weightedLoad())
    }
}
