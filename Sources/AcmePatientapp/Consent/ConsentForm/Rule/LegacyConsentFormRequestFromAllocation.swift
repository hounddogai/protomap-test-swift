import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureAllocationsForRequest(_ items: [DisclosureAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveLegacyConsentFormRequestsFromAllocation(_ items: [DisclosureAllocation]) -> [LegacyConsentFormRequest] {
        var out: [LegacyConsentFormRequest] = []
        for item in items {
            let derived = newLegacyConsentFormRequest(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeLegacyConsentFormRequest(_ item: LegacyConsentFormRequest) -> String {
        return classifyAdaptiveDisclosureException(item.effectiveExposure())
    }
}
