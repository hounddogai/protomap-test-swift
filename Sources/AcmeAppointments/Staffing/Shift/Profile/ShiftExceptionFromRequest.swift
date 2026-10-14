import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanRequestsForException(_ items: [AcuityPlanRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveShiftExceptionsFromRequest(_ items: [AcuityPlanRequest]) -> [ShiftException] {
        var out: [ShiftException] = []
        for item in items {
            let derived = newShiftException(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyShiftException(_ item: ShiftException) -> Double {
        return acuityPlanRequestWeight(4, active: true)
    }
}
