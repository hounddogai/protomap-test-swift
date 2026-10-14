import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseTargetsForPlan(_ items: [DispenseTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveLenientInventoryPlansFromTarget(_ items: [DispenseTarget]) -> [LenientInventoryPlan] {
        var out: [LenientInventoryPlan] = []
        for item in items {
            let derived = newLenientInventoryPlan(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeLenientInventoryPlan(_ item: LenientInventoryPlan) -> String {
        return dispenseAuditBucket(item.adjustedExposure())
    }
}
