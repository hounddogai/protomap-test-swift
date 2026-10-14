import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolScoresForCheckpoint(_ items: [FloatPoolScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveAcuityPlanCheckpointsFromScore(_ items: [FloatPoolScore]) -> [AcuityPlanCheckpoint] {
        var out: [AcuityPlanCheckpoint] = []
        for item in items {
            let derived = newAcuityPlanCheckpoint(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileAcuityPlanCheckpoint(_ item: AcuityPlanCheckpoint) -> String {
        return primaryFloatPoolMilestoneBucket(item.projectedLoad())
    }
}
