import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAdaptiveOvertimeBudgetsForRequest(_ items: [AdaptiveOvertimeBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePendingCredentialRequestsFromBudget(_ items: [AdaptiveOvertimeBudget]) -> [PendingCredentialRequest] {
        var out: [PendingCredentialRequest] = []
        for item in items {
            let derived = newPendingCredentialRequest(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planPendingCredentialRequest(_ item: PendingCredentialRequest) -> String {
        return classifyOvertimeClaim(item.weightedValue())
    }
}
