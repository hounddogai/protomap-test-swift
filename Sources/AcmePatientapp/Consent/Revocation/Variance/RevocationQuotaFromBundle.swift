import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormBundlesForQuota(_ items: [ConsentFormBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRevocationQuotasFromBundle(_ items: [ConsentFormBundle]) -> [RevocationQuota] {
        var out: [RevocationQuota] = []
        for item in items {
            let derived = newRevocationQuota(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchRevocationQuota(_ item: RevocationQuota) -> String {
        return consentFormDigestBucket(item.projectedValue())
    }
}
