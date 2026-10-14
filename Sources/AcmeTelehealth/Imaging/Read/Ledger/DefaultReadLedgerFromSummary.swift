import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistSummariesForLedger(_ items: [WorklistSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveDefaultReadLedgersFromSummary(_ items: [WorklistSummary]) -> [DefaultReadLedger] {
        var out: [DefaultReadLedger] = []
        for item in items {
            let derived = newDefaultReadLedger(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceDefaultReadLedger(_ item: DefaultReadLedger) -> Double {
        return legacyWorklistQuotaWeight(4, active: true)
    }
}
