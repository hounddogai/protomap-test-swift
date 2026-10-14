import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffLedgersForException(_ items: [HandoffLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRoundingExceptionsFromLedger(_ items: [HandoffLedger]) -> [RoundingException] {
        var out: [RoundingException] = []
        for item in items {
            let derived = newRoundingException(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRoundingException(_ item: RoundingException) -> String {
        return handoffRequestBucket(item.measuredValue())
    }
}
