import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapSlotsForManifest(_ items: [CareGapSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func derivePendingProgramManifestsFromSlot(_ items: [CareGapSlot]) -> [PendingProgramManifest] {
        var out: [PendingProgramManifest] = []
        for item in items {
            let derived = newPendingProgramManifest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizePendingProgramManifest(_ item: PendingProgramManifest) -> Double {
        return seasonalCareGapAssignmentWeight(7, active: true)
    }
}
