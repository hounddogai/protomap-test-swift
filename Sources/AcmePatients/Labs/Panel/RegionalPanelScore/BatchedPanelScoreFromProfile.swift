import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLegacySpecimenProfilesForScore(_ items: [LegacySpecimenProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveBatchedPanelScoresFromProfile(_ items: [LegacySpecimenProfile]) -> [BatchedPanelScore] {
        var out: [BatchedPanelScore] = []
        for item in items {
            let derived = newBatchedPanelScore(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleBatchedPanelScore(_ item: BatchedPanelScore) -> String {
        return defaultSpecimenReservationBucket(item.projectedTotal())
    }
}
