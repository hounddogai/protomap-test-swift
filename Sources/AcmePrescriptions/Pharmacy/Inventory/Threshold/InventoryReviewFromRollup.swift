import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRegionalSubstitutionRollupsForReview(_ items: [RegionalSubstitutionRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveInventoryReviewsFromRollup(_ items: [RegionalSubstitutionRollup]) -> [InventoryReview] {
        var out: [InventoryReview] = []
        for item in items {
            let derived = newInventoryReview(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeInventoryReview(_ item: InventoryReview) -> Double {
        return substitutionGroupWeight(3, active: true)
    }
}
