import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryAcuityPlanQuotasForAudit(_ items: [PrimaryAcuityPlanQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveSeasonalShiftAuditsFromQuota(_ items: [PrimaryAcuityPlanQuota]) -> [SeasonalShiftAudit] {
        var out: [SeasonalShiftAudit] = []
        for item in items {
            let derived = newSeasonalShiftAudit(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeSeasonalShiftAudit(_ item: SeasonalShiftAudit) -> String {
        return classifyAcuityPlanRecord(item.weightedLoad())
    }
}
