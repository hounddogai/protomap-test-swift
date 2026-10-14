import AcmePlatform
import Foundation

extension Labs {
    static func summarizeManualAccessionTiersForRollup(_ items: [ManualAccessionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveCourierRollupsFromTier(_ items: [ManualAccessionTier]) -> [CourierRollup] {
        var out: [CourierRollup] = []
        for item in items {
            let derived = newCourierRollup(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyCourierRollup(_ item: CourierRollup) -> Double {
        return strictAccessionAssignmentWeight(7, active: true)
    }
}
