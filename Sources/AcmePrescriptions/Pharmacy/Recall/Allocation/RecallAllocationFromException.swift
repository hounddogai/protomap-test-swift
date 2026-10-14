import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionExceptionsForAllocation(_ items: [InteractionException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRecallAllocationsFromException(_ items: [InteractionException]) -> [RecallAllocation] {
        var out: [RecallAllocation] = []
        for item in items {
            let derived = newRecallAllocation(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileRecallAllocation(_ item: RecallAllocation) -> String {
        return normalizeInteractionExceptionCode(item.code)
    }
}
