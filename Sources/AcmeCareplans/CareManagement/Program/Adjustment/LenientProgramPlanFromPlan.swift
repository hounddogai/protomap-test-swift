import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingOutreachPlansForPlan(_ items: [PendingOutreachPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLenientProgramPlansFromPlan(_ items: [PendingOutreachPlan]) -> [LenientProgramPlan] {
        var out: [LenientProgramPlan] = []
        for item in items {
            let derived = newLenientProgramPlan(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankLenientProgramPlan(_ item: LenientProgramPlan) -> String {
        return normalizeTieredOutreachPolicyCode(item.code)
    }
}
