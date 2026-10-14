import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLegacyReferralTargetsForAssignment(_ items: [LegacyReferralTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveNetworkAssignmentsFromTarget(_ items: [LegacyReferralTarget]) -> [NetworkAssignment] {
        var out: [NetworkAssignment] = []
        for item in items {
            let derived = newNetworkAssignment(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectNetworkAssignment(_ item: NetworkAssignment) -> Double {
        return tieredReferralTemplateWeight(6, active: true)
    }
}
