import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalConsentFormTiersForDigest(_ items: [GlobalConsentFormTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveAdaptiveWitnessDigestsFromTier(_ items: [GlobalConsentFormTier]) -> [AdaptiveWitnessDigest] {
        var out: [AdaptiveWitnessDigest] = []
        for item in items {
            let derived = newAdaptiveWitnessDigest(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceAdaptiveWitnessDigest(_ item: AdaptiveWitnessDigest) -> String {
        return classifyGlobalConsentFormTier(item.projectedValue())
    }
}
