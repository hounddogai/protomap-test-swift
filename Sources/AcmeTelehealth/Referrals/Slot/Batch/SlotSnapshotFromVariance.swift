import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralVariancesForSnapshot(_ items: [ReferralVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveSlotSnapshotsFromVariance(_ items: [ReferralVariance]) -> [SlotSnapshot] {
        var out: [SlotSnapshot] = []
        for item in items {
            let derived = newSlotSnapshot(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applySlotSnapshot(_ item: SlotSnapshot) -> String {
        return referralVarianceBucket(item.weightedExposure())
    }
}
