import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormAdjustmentsForClaim(_ items: [ConsentFormAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRevocationClaimsFromAdjustment(_ items: [ConsentFormAdjustment]) -> [RevocationClaim] {
        var out: [RevocationClaim] = []
        for item in items {
            let derived = newRevocationClaim(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRevocationClaim(_ item: RevocationClaim) -> String {
        return consentFormWindowBucket(item.adjustedTotal())
    }
}
