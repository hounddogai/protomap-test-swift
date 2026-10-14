import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotSnapshotsForMapping(_ items: [SlotSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveFallbackReferralMappingsFromSnapshot(_ items: [SlotSnapshot]) -> [FallbackReferralMapping] {
        var out: [FallbackReferralMapping] = []
        for item in items {
            let derived = newFallbackReferralMapping(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveFallbackReferralMapping(_ item: FallbackReferralMapping) -> Double {
        return slotSnapshotWeight(4, active: true)
    }
}
