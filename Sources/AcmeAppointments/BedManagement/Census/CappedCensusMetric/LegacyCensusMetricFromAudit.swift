import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeSeasonalCensusAuditsForMetric(_ items: [SeasonalCensusAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveLegacyCensusMetricsFromAudit(_ items: [SeasonalCensusAudit]) -> [LegacyCensusMetric] {
        var out: [LegacyCensusMetric] = []
        for item in items {
            let derived = newLegacyCensusMetric(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileLegacyCensusMetric(_ item: LegacyCensusMetric) -> String {
        return normalizeSeasonalCensusAuditCode(item.code)
    }
}
