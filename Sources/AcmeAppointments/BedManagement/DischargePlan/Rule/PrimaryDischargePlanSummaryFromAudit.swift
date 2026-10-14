import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeSeasonalCensusAuditsForSummary(_ items: [SeasonalCensusAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func derivePrimaryDischargePlanSummariesFromAudit(_ items: [SeasonalCensusAudit]) -> [PrimaryDischargePlanSummary] {
        var out: [PrimaryDischargePlanSummary] = []
        for item in items {
            let derived = newPrimaryDischargePlanSummary(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitPrimaryDischargePlanSummary(_ item: PrimaryDischargePlanSummary) -> String {
        return classifyPendingCensusLedger(item.weightedLoad())
    }
}
