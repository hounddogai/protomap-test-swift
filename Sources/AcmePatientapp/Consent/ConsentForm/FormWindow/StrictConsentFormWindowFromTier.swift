import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormTiersForWindow(_ items: [ConsentFormTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveStrictConsentFormWindowsFromTier(_ items: [ConsentFormTier]) -> [StrictConsentFormWindow] {
        var out: [StrictConsentFormWindow] = []
        for item in items {
            let derived = newStrictConsentFormWindow(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreStrictConsentFormWindow(_ item: StrictConsentFormWindow) -> String {
        return consentFormTierBucket(item.weightedVolume())
    }
}
