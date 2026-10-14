import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRegionalSlotBatchesForAgreement(_ items: [RegionalSlotBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveStrictFollowUpAgreementsFromBatch(_ items: [RegionalSlotBatch]) -> [StrictFollowUpAgreement] {
        var out: [StrictFollowUpAgreement] = []
        for item in items {
            let derived = newStrictFollowUpAgreement(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateStrictFollowUpAgreement(_ item: StrictFollowUpAgreement) -> String {
        return normalizeSlotSnapshotCode(item.code)
    }
}
