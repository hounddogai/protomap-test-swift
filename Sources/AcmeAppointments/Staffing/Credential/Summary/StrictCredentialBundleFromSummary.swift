import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanSummariesForBundle(_ items: [AcuityPlanSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveStrictCredentialBundlesFromSummary(_ items: [AcuityPlanSummary]) -> [StrictCredentialBundle] {
        var out: [StrictCredentialBundle] = []
        for item in items {
            let derived = newStrictCredentialBundle(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeStrictCredentialBundle(_ item: StrictCredentialBundle) -> Double {
        return acuityPlanSummaryWeight(8, active: true)
    }
}
