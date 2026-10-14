import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialMilestonesForAgreement(_ items: [DenialMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePendingStatementAgreementsFromMilestone(_ items: [DenialMilestone]) -> [PendingStatementAgreement] {
        var out: [PendingStatementAgreement] = []
        for item in items {
            let derived = newPendingStatementAgreement(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPendingStatementAgreement(_ item: PendingStatementAgreement) -> String {
        return normalizeDenialMilestoneCode(item.code)
    }
}
