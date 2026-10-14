import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanAllocationsForMilestone(_ items: [AcuityPlanAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveDefaultAcuityPlanMilestonesFromAllocation(_ items: [AcuityPlanAllocation]) -> [DefaultAcuityPlanMilestone] {
        var out: [DefaultAcuityPlanMilestone] = []
        for item in items {
            let derived = newDefaultAcuityPlanMilestone(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitDefaultAcuityPlanMilestone(_ item: DefaultAcuityPlanMilestone) -> String {
        return classifyLenientAcuityPlanBaseline(item.measuredValue())
    }
}
