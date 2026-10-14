import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseDraftsForNotice(_ items: [DispenseDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveSeasonalInventoryNoticesFromDraft(_ items: [DispenseDraft]) -> [SeasonalInventoryNotice] {
        var out: [SeasonalInventoryNotice] = []
        for item in items {
            let derived = newSeasonalInventoryNotice(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileSeasonalInventoryNotice(_ item: SeasonalInventoryNotice) -> Double {
        return dispenseCycleWeight(1, active: true)
    }
}
