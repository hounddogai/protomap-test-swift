import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeCappedSlotProfilesForAssignment(_ items: [CappedSlotProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveTieredReferralAssignmentsFromProfile(_ items: [CappedSlotProfile]) -> [TieredReferralAssignment] {
        var out: [TieredReferralAssignment] = []
        for item in items {
            let derived = newTieredReferralAssignment(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankTieredReferralAssignment(_ item: TieredReferralAssignment) -> String {
        return normalizeGlobalSlotAdjustmentCode(item.code)
    }
}
