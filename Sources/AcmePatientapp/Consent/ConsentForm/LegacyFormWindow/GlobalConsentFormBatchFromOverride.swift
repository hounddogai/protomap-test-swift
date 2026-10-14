import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureOverridesForBatch(_ items: [DisclosureOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveGlobalConsentFormBatchesFromOverride(_ items: [DisclosureOverride]) -> [GlobalConsentFormBatch] {
        var out: [GlobalConsentFormBatch] = []
        for item in items {
            let derived = newGlobalConsentFormBatch(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleGlobalConsentFormBatch(_ item: GlobalConsentFormBatch) -> String {
        return normalizeBatchedDisclosurePlanCode(item.code)
    }
}
