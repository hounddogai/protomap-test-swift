import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeStrictSlotBatchesForDigest(_ items: [StrictSlotBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredReferralDigestsFromBatch(_ items: [StrictSlotBatch]) -> [TieredReferralDigest] {
        var out: [TieredReferralDigest] = []
        for item in items {
            let derived = newTieredReferralDigest(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyTieredReferralDigest(_ item: TieredReferralDigest) -> String {
        return normalizeSlotDraftCode(item.code)
    }
}
