import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureLedgersForAdjustment(_ items: [ClosureLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveClosureAdjustmentsFromLedger(_ items: [ClosureLedger]) -> [ClosureAdjustment] {
        var out: [ClosureAdjustment] = []
        for item in items {
            let derived = newClosureAdjustment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planClosureAdjustment(_ item: ClosureAdjustment) -> String {
        return closureEntryBucket(item.netLoad())
    }
}
