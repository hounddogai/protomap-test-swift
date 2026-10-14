import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationPlansForSnapshot(_ items: [AuthorizationPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveManualRemittanceSnapshotsFromPlan(_ items: [AuthorizationPlan]) -> [ManualRemittanceSnapshot] {
        var out: [ManualRemittanceSnapshot] = []
        for item in items {
            let derived = newManualRemittanceSnapshot(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignManualRemittanceSnapshot(_ item: ManualRemittanceSnapshot) -> String {
        return classifyAuthorizationTemplate(item.projectedValue())
    }
}
