import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingModalityTargetsForSummary(_ items: [PendingModalityTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveTieredStudySummariesFromTarget(_ items: [PendingModalityTarget]) -> [TieredStudySummary] {
        var out: [TieredStudySummary] = []
        for item in items {
            let derived = newTieredStudySummary(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeTieredStudySummary(_ item: TieredStudySummary) -> Double {
        return pendingModalityTargetWeight(3, active: true)
    }
}
