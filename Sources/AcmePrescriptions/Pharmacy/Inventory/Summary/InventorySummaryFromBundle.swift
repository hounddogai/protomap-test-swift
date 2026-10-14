import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryBundlesForSummary(_ items: [InventoryBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveInventorySummariesFromBundle(_ items: [InventoryBundle]) -> [InventorySummary] {
        var out: [InventorySummary] = []
        for item in items {
            let derived = newInventorySummary(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyInventorySummary(_ item: InventorySummary) -> String {
        return inventoryForecastBucket(item.netTotal())
    }
}
