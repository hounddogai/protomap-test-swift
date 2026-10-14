import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseDraftsForCycle(_ items: [DispenseDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveWeightedDispenseCyclesFromDraft(_ items: [DispenseDraft]) -> [WeightedDispenseCycle] {
        var out: [WeightedDispenseCycle] = []
        for item in items {
            let derived = newWeightedDispenseCycle(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeWeightedDispenseCycle(_ item: WeightedDispenseCycle) -> String {
        return dispenseDraftBucket(item.adjustedLoad())
    }
}
