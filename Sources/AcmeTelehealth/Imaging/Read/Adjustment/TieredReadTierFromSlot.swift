import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCappedStudySlotsForTier(_ items: [CappedStudySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveTieredReadTiersFromSlot(_ items: [CappedStudySlot]) -> [TieredReadTier] {
        var out: [TieredReadTier] = []
        for item in items {
            let derived = newTieredReadTier(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeTieredReadTier(_ item: TieredReadTier) -> String {
        return lenientStudyTargetBucket(item.weightedTotal())
    }
}
