import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityAgreementsForRollup(_ items: [PriorityAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveWorklistRollupsFromAgreement(_ items: [PriorityAgreement]) -> [WorklistRollup] {
        var out: [WorklistRollup] = []
        for item in items {
            let derived = newWorklistRollup(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWorklistRollup(_ item: WorklistRollup) -> Double {
        return priorityAgreementWeight(3, active: true)
    }
}
