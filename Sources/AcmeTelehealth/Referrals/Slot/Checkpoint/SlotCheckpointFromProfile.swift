import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralProfilesForCheckpoint(_ items: [ReferralProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveSlotCheckpointsFromProfile(_ items: [ReferralProfile]) -> [SlotCheckpoint] {
        var out: [SlotCheckpoint] = []
        for item in items {
            let derived = newSlotCheckpoint(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankSlotCheckpoint(_ item: SlotCheckpoint) -> String {
        return referralProfileBucket(item.weightedExposure())
    }
}
