import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeStrictOvertimeAgreementsForSummary(_ items: [StrictOvertimeAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveLegacyAcuityPlanSummariesFromAgreement(_ items: [StrictOvertimeAgreement]) -> [LegacyAcuityPlanSummary] {
        var out: [LegacyAcuityPlanSummary] = []
        for item in items {
            let derived = newLegacyAcuityPlanSummary(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveLegacyAcuityPlanSummary(_ item: LegacyAcuityPlanSummary) -> String {
        return normalizeRollingOvertimeBudgetCode(item.code)
    }
}
