import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePendingRemittanceMappingsForMilestone(_ items: [PendingRemittanceMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveLenientStatementMilestonesFromMapping(_ items: [PendingRemittanceMapping]) -> [LenientStatementMilestone] {
        var out: [LenientStatementMilestone] = []
        for item in items {
            let derived = newLenientStatementMilestone(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLenientStatementMilestone(_ item: LenientStatementMilestone) -> String {
        return classifyPendingRemittanceMapping(item.effectiveValue())
    }
}
