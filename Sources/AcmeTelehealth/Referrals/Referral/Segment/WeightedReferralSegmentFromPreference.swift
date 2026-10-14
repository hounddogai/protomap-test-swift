import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotPreferencesForSegment(_ items: [SlotPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveWeightedReferralSegmentsFromPreference(_ items: [SlotPreference]) -> [WeightedReferralSegment] {
        var out: [WeightedReferralSegment] = []
        for item in items {
            let derived = newWeightedReferralSegment(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitWeightedReferralSegment(_ item: WeightedReferralSegment) -> String {
        return normalizeGlobalSlotEstimateCode(item.code)
    }
}
