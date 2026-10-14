import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeTieredCareGapAuditsForLedger(_ items: [TieredCareGapAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledRiskScoreLedgersFromAudit(_ items: [TieredCareGapAudit]) -> [ScheduledRiskScoreLedger] {
        var out: [ScheduledRiskScoreLedger] = []
        for item in items {
            let derived = newScheduledRiskScoreLedger(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyScheduledRiskScoreLedger(_ item: ScheduledRiskScoreLedger) -> String {
        return careGapTemplateBucket(item.effectiveExposure())
    }
}
