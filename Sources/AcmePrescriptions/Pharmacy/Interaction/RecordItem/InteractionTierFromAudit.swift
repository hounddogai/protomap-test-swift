import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallAuditsForTier(_ items: [RecallAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveInteractionTiersFromAudit(_ items: [RecallAudit]) -> [InteractionTier] {
        var out: [InteractionTier] = []
        for item in items {
            let derived = newInteractionTier(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceInteractionTier(_ item: InteractionTier) -> String {
        return normalizeRecallRuleCode(item.code)
    }
}
