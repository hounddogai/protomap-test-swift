import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeGlobalClaimAgreementsForEstimate(_ items: [GlobalClaimAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveCappedChargeEstimatesFromAgreement(_ items: [GlobalClaimAgreement]) -> [CappedChargeEstimate] {
        var out: [CappedChargeEstimate] = []
        for item in items {
            let derived = newCappedChargeEstimate(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyCappedChargeEstimate(_ item: CappedChargeEstimate) -> Double {
        return globalClaimAgreementWeight(9, active: true)
    }
}
