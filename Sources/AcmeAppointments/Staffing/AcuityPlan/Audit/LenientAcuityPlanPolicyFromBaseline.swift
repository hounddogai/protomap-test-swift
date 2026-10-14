import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalShiftBaselinesForPolicy(_ items: [RegionalShiftBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveLenientAcuityPlanPoliciesFromBaseline(_ items: [RegionalShiftBaseline]) -> [LenientAcuityPlanPolicy] {
        var out: [LenientAcuityPlanPolicy] = []
        for item in items {
            let derived = newLenientAcuityPlanPolicy(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectLenientAcuityPlanPolicy(_ item: LenientAcuityPlanPolicy) -> String {
        return normalizeShiftRollupCode(item.code)
    }
}
