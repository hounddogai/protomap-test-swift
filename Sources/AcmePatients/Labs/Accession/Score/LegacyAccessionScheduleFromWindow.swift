import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryResultWindowsForSchedule(_ items: [PrimaryResultWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveLegacyAccessionSchedulesFromWindow(_ items: [PrimaryResultWindow]) -> [LegacyAccessionSchedule] {
        var out: [LegacyAccessionSchedule] = []
        for item in items {
            let derived = newLegacyAccessionSchedule(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankLegacyAccessionSchedule(_ item: LegacyAccessionSchedule) -> Double {
        return batchedResultCheckpointWeight(8, active: true)
    }
}
