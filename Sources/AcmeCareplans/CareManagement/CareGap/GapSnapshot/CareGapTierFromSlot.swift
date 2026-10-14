import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeManualOutreachSlotsForTier(_ items: [ManualOutreachSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveCareGapTiersFromSlot(_ items: [ManualOutreachSlot]) -> [CareGapTier] {
        var out: [CareGapTier] = []
        for item in items {
            let derived = newCareGapTier(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planCareGapTier(_ item: CareGapTier) -> String {
        return normalizePrimaryOutreachProposalCode(item.code)
    }
}
