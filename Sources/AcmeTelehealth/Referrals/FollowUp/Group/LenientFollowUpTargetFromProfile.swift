import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotProfilesForTarget(_ items: [SlotProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientFollowUpTargetsFromProfile(_ items: [SlotProfile]) -> [LenientFollowUpTarget] {
        var out: [LenientFollowUpTarget] = []
        for item in items {
            let derived = newLenientFollowUpTarget(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planLenientFollowUpTarget(_ item: LenientFollowUpTarget) -> String {
        return pendingSlotManifestBucket(item.netLoad())
    }
}
