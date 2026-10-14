import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedShiftSnapshotsForScore(_ items: [CappedShiftSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func derivePrimaryAcuityPlanScoresFromSnapshot(_ items: [CappedShiftSnapshot]) -> [PrimaryAcuityPlanScore] {
        var out: [PrimaryAcuityPlanScore] = []
        for item in items {
            let derived = newPrimaryAcuityPlanScore(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergePrimaryAcuityPlanScore(_ item: PrimaryAcuityPlanScore) -> String {
        return strictShiftThresholdBucket(item.effectiveExposure())
    }
}
