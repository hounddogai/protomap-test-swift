import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryAcuityPlanTargetsForException(_ items: [PrimaryAcuityPlanTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveAcuityPlanExceptionsFromTarget(_ items: [PrimaryAcuityPlanTarget]) -> [AcuityPlanException] {
        var out: [AcuityPlanException] = []
        for item in items {
            let derived = newAcuityPlanException(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignAcuityPlanException(_ item: AcuityPlanException) -> Double {
        return acuityPlanGroupWeight(6, active: true)
    }
}
