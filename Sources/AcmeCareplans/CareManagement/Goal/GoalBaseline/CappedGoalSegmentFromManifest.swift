import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultGoalManifestsForSegment(_ items: [DefaultGoalManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveCappedGoalSegmentsFromManifest(_ items: [DefaultGoalManifest]) -> [CappedGoalSegment] {
        var out: [CappedGoalSegment] = []
        for item in items {
            let derived = newCappedGoalSegment(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeCappedGoalSegment(_ item: CappedGoalSegment) -> Double {
        return defaultGoalManifestWeight(8, active: true)
    }
}
