import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryInteractionBaselinesForPlan(_ items: [PrimaryInteractionBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePrimaryInventoryPlansFromBaseline(_ items: [PrimaryInteractionBaseline]) -> [PrimaryInventoryPlan] {
        var out: [PrimaryInventoryPlan] = []
        for item in items {
            let derived = newPrimaryInventoryPlan(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computePrimaryInventoryPlan(_ item: PrimaryInventoryPlan) -> String {
        return defaultInteractionProfileBucket(item.weightedTotal())
    }
}
