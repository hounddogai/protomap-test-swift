import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLenientFloatPoolEstimatesForBaseline(_ items: [LenientFloatPoolEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveCredentialBaselinesFromEstimate(_ items: [LenientFloatPoolEstimate]) -> [CredentialBaseline] {
        var out: [CredentialBaseline] = []
        for item in items {
            let derived = newCredentialBaseline(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyCredentialBaseline(_ item: CredentialBaseline) -> String {
        return normalizeScheduledFloatPoolBudgetCode(item.code)
    }
}
