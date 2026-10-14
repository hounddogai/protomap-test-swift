import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveInventoryScoresForReview(_ items: [AdaptiveInventoryScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveInventoryReviewsFromScore(_ items: [AdaptiveInventoryScore]) -> [InventoryReview] {
        var out: [InventoryReview] = []
        for item in items {
            let derived = newInventoryReview(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankInventoryReview(_ item: InventoryReview) -> String {
        return normalizeInventoryCycleCode(item.code)
    }
}
