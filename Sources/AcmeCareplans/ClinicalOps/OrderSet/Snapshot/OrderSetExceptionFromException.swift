import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingExceptionsForException(_ items: [RoundingException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOrderSetExceptionsFromException(_ items: [RoundingException]) -> [OrderSetException] {
        var out: [OrderSetException] = []
        for item in items {
            let derived = newOrderSetException(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreOrderSetException(_ item: OrderSetException) -> String {
        return classifyRoundingException(item.weightedTotal())
    }
}
