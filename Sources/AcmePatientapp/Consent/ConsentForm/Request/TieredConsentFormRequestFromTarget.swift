import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalDisclosureTargetsForRequest(_ items: [RegionalDisclosureTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveTieredConsentFormRequestsFromTarget(_ items: [RegionalDisclosureTarget]) -> [TieredConsentFormRequest] {
        var out: [TieredConsentFormRequest] = []
        for item in items {
            let derived = newTieredConsentFormRequest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreTieredConsentFormRequest(_ item: TieredConsentFormRequest) -> String {
        return classifyRegionalDisclosureTarget(item.effectiveVolume())
    }
}
