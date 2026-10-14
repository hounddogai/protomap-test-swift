import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryFloatPoolAssignmentsForClaim(_ items: [PrimaryFloatPoolAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalAcuityPlanClaimsFromAssignment(_ items: [PrimaryFloatPoolAssignment]) -> [RegionalAcuityPlanClaim] {
        var out: [RegionalAcuityPlanClaim] = []
        for item in items {
            let derived = newRegionalAcuityPlanClaim(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreRegionalAcuityPlanClaim(_ item: RegionalAcuityPlanClaim) -> Double {
        return primaryFloatPoolAssignmentWeight(9, active: true)
    }
}
