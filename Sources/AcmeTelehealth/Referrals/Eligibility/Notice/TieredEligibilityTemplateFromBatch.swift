import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredFollowUpBatchesForTemplate(_ items: [TieredFollowUpBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveTieredEligibilityTemplatesFromBatch(_ items: [TieredFollowUpBatch]) -> [TieredEligibilityTemplate] {
        var out: [TieredEligibilityTemplate] = []
        for item in items {
            let derived = newTieredEligibilityTemplate(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeTieredEligibilityTemplate(_ item: TieredEligibilityTemplate) -> Double {
        return pendingFollowUpNoticeWeight(1, active: true)
    }
}
