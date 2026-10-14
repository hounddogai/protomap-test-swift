import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredSlotMappingsForException(_ items: [TieredSlotMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveTieredReferralExceptionsFromMapping(_ items: [TieredSlotMapping]) -> [TieredReferralException] {
        var out: [TieredReferralException] = []
        for item in items {
            let derived = newTieredReferralException(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleTieredReferralException(_ item: TieredReferralException) -> String {
        return seasonalSlotMappingBucket(item.adjustedLoad())
    }
}
