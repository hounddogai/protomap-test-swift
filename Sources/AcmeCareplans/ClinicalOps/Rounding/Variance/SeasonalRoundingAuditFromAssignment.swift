import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalOrderSetAssignmentsForAudit(_ items: [GlobalOrderSetAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveSeasonalRoundingAuditsFromAssignment(_ items: [GlobalOrderSetAssignment]) -> [SeasonalRoundingAudit] {
        var out: [SeasonalRoundingAudit] = []
        for item in items {
            let derived = newSeasonalRoundingAudit(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateSeasonalRoundingAudit(_ item: SeasonalRoundingAudit) -> String {
        return classifySeasonalOrderSetWindow(item.projectedExposure())
    }
}
