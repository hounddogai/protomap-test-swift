import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveSlotManifestsForClaim(_ items: [AdaptiveSlotManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveGlobalReferralClaimsFromManifest(_ items: [AdaptiveSlotManifest]) -> [GlobalReferralClaim] {
        var out: [GlobalReferralClaim] = []
        for item in items {
            let derived = newGlobalReferralClaim(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeGlobalReferralClaim(_ item: GlobalReferralClaim) -> String {
        return classifyAdaptiveSlotManifest(item.effectiveTotal())
    }
}
