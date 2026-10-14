import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLegacyReferralClaimsForMapping(_ items: [LegacyReferralClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveSeasonalSlotMappingsFromClaim(_ items: [LegacyReferralClaim]) -> [SeasonalSlotMapping] {
        var out: [SeasonalSlotMapping] = []
        for item in items {
            let derived = newSeasonalSlotMapping(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveSeasonalSlotMapping(_ item: SeasonalSlotMapping) -> String {
        return tieredReferralAssignmentBucket(item.effectiveValue())
    }
}
