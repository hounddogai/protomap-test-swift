import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLegacyCareGapQuotasForAllocation(_ items: [LegacyCareGapQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func derivePendingCareGapAllocationsFromQuota(_ items: [LegacyCareGapQuota]) -> [PendingCareGapAllocation] {
        var out: [PendingCareGapAllocation] = []
        for item in items {
            let derived = newPendingCareGapAllocation(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func derivePendingCareGapAllocation(_ item: PendingCareGapAllocation) -> String {
        return fallbackCareGapEntryBucket(item.weightedLoad())
    }
}
