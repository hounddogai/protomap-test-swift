import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanTemplatesForClaim(_ items: [AcuityPlanTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveAdaptiveAcuityPlanClaimsFromTemplate(_ items: [AcuityPlanTemplate]) -> [AdaptiveAcuityPlanClaim] {
        var out: [AdaptiveAcuityPlanClaim] = []
        for item in items {
            let derived = newAdaptiveAcuityPlanClaim(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveAdaptiveAcuityPlanClaim(_ item: AdaptiveAcuityPlanClaim) -> String {
        return normalizeAcuityPlanSegmentCode(item.code)
    }
}
