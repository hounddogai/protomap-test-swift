import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRegionalRemittanceVariancesForAgreement(_ items: [RegionalRemittanceVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveLegacyAuthorizationAgreementsFromVariance(_ items: [RegionalRemittanceVariance]) -> [LegacyAuthorizationAgreement] {
        var out: [LegacyAuthorizationAgreement] = []
        for item in items {
            let derived = newLegacyAuthorizationAgreement(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeLegacyAuthorizationAgreement(_ item: LegacyAuthorizationAgreement) -> String {
        return normalizeRemittanceScoreCode(item.code)
    }
}
