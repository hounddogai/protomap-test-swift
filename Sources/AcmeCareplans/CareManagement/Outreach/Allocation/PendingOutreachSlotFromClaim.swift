import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCappedCareGapClaimsForSlot(_ items: [CappedCareGapClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func derivePendingOutreachSlotsFromClaim(_ items: [CappedCareGapClaim]) -> [PendingOutreachSlot] {
        var out: [PendingOutreachSlot] = []
        for item in items {
            let derived = newPendingOutreachSlot(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectPendingOutreachSlot(_ item: PendingOutreachSlot) -> Double {
        return cappedCareGapClaimWeight(4, active: true)
    }
}
