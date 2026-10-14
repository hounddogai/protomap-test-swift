import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolAdjustmentsForAllocation(_ items: [FloatPoolAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryCredentialAllocationsFromAdjustment(_ items: [FloatPoolAdjustment]) -> [PrimaryCredentialAllocation] {
        var out: [PrimaryCredentialAllocation] = []
        for item in items {
            let derived = newPrimaryCredentialAllocation(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func derivePrimaryCredentialAllocation(_ item: PrimaryCredentialAllocation) -> String {
        return classifyFloatPoolAdjustment(item.effectiveLoad())
    }
}
