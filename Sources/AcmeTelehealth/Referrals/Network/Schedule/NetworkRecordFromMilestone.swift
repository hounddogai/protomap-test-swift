import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePendingReferralMilestonesForRecord(_ items: [PendingReferralMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveNetworkRecordsFromMilestone(_ items: [PendingReferralMilestone]) -> [NetworkRecord] {
        var out: [NetworkRecord] = []
        for item in items {
            let derived = newNetworkRecord(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreNetworkRecord(_ item: NetworkRecord) -> Double {
        return referralClaimWeight(4, active: true)
    }
}
