import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientCleaningMetricsForLedger(_ items: [LenientCleaningMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func derivePendingCensusLedgersFromMetric(_ items: [LenientCleaningMetric]) -> [PendingCensusLedger] {
        var out: [PendingCensusLedger] = []
        for item in items {
            let derived = newPendingCensusLedger(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolvePendingCensusLedger(_ item: PendingCensusLedger) -> String {
        return normalizeLenientCleaningMetricCode(item.code)
    }
}
