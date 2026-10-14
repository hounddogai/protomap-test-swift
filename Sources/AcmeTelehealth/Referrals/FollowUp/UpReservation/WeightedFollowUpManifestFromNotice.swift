import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalSlotNoticesForManifest(_ items: [SeasonalSlotNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveWeightedFollowUpManifestsFromNotice(_ items: [SeasonalSlotNotice]) -> [WeightedFollowUpManifest] {
        var out: [WeightedFollowUpManifest] = []
        for item in items {
            let derived = newWeightedFollowUpManifest(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileWeightedFollowUpManifest(_ item: WeightedFollowUpManifest) -> String {
        return seasonalSlotNoticeBucket(item.measuredValue())
    }
}
