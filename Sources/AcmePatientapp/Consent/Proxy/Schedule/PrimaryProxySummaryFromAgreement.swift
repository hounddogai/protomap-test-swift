import AcmePlatform
import Foundation

extension Consent {
    static func summarizeFallbackDisclosureAgreementsForSummary(_ items: [FallbackDisclosureAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func derivePrimaryProxySummariesFromAgreement(_ items: [FallbackDisclosureAgreement]) -> [PrimaryProxySummary] {
        var out: [PrimaryProxySummary] = []
        for item in items {
            let derived = newPrimaryProxySummary(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balancePrimaryProxySummary(_ item: PrimaryProxySummary) -> Double {
        return fallbackDisclosureAgreementWeight(2, active: true)
    }
}
