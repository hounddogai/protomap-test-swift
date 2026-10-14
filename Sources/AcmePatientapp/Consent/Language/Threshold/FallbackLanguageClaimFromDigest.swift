import AcmePlatform
import Foundation

extension Consent {
    static func summarizeBatchedRevocationDigestsForClaim(_ items: [BatchedRevocationDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveFallbackLanguageClaimsFromDigest(_ items: [BatchedRevocationDigest]) -> [FallbackLanguageClaim] {
        var out: [FallbackLanguageClaim] = []
        for item in items {
            let derived = newFallbackLanguageClaim(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveFallbackLanguageClaim(_ item: FallbackLanguageClaim) -> String {
        return classifyCappedRevocationBundle(item.projectedVolume())
    }
}
