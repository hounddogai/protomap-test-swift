import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePendingRecallAuditsForScore(_ items: [PendingRecallAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveFallbackInventoryScoresFromAudit(_ items: [PendingRecallAudit]) -> [FallbackInventoryScore] {
        var out: [FallbackInventoryScore] = []
        for item in items {
            let derived = newFallbackInventoryScore(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceFallbackInventoryScore(_ item: FallbackInventoryScore) -> String {
        return normalizeDefaultRecallProposalCode(item.code)
    }
}
