import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalSpecimenLedgersForNotice(_ items: [GlobalSpecimenLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveBatchedAccessionNoticesFromLedger(_ items: [GlobalSpecimenLedger]) -> [BatchedAccessionNotice] {
        var out: [BatchedAccessionNotice] = []
        for item in items {
            let derived = newBatchedAccessionNotice(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreBatchedAccessionNotice(_ item: BatchedAccessionNotice) -> String {
        return classifyFallbackSpecimenRequest(item.effectiveLoad())
    }
}
