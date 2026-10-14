import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionRecordsForLedger(_ items: [SubstitutionRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func derivePendingRecallLedgersFromRecord(_ items: [SubstitutionRecord]) -> [PendingRecallLedger] {
        var out: [PendingRecallLedger] = []
        for item in items {
            let derived = newPendingRecallLedger(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computePendingRecallLedger(_ item: PendingRecallLedger) -> String {
        return classifyManualSubstitutionBatch(item.netVolume())
    }
}
