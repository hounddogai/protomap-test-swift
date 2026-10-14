import AcmePlatform
import Foundation

extension Consent {
    static func summarizeFallbackDisclosureProfilesForNotice(_ items: [FallbackDisclosureProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveFallbackConsentFormNoticesFromProfile(_ items: [FallbackDisclosureProfile]) -> [FallbackConsentFormNotice] {
        var out: [FallbackConsentFormNotice] = []
        for item in items {
            let derived = newFallbackConsentFormNotice(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateFallbackConsentFormNotice(_ item: FallbackConsentFormNotice) -> Double {
        return disclosureRequestWeight(7, active: true)
    }
}
