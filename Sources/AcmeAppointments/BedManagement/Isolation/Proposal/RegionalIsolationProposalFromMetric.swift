import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientCleaningMetricsForProposal(_ items: [LenientCleaningMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRegionalIsolationProposalsFromMetric(_ items: [LenientCleaningMetric]) -> [RegionalIsolationProposal] {
        var out: [RegionalIsolationProposal] = []
        for item in items {
            let derived = newRegionalIsolationProposal(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRegionalIsolationProposal(_ item: RegionalIsolationProposal) -> String {
        return normalizePendingCleaningReservationCode(item.code)
    }
}
