import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadPlansForAgreement(_ items: [ReadPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCareProtocolAgreementsFromPlan(_ items: [ReadPlan]) -> [CareProtocolAgreement] {
        var out: [CareProtocolAgreement] = []
        for item in items {
            let derived = newCareProtocolAgreement(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCareProtocolAgreement(_ item: CareProtocolAgreement) -> String {
        return normalizeReadPlanCode(item.code)
    }
}
