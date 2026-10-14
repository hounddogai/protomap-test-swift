import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryEligibilityQuotasForSlot(_ items: [PrimaryEligibilityQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func derivePendingEligibilitySlotsFromQuota(_ items: [PrimaryEligibilityQuota]) -> [PendingEligibilitySlot] {
        var out: [PendingEligibilitySlot] = []
        for item in items {
            let derived = newPendingEligibilitySlot(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizePendingEligibilitySlot(_ item: PendingEligibilitySlot) -> String {
        return classifyCappedEligibilityVariance(item.adjustedTotal())
    }
}
