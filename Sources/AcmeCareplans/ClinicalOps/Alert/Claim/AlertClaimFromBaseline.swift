import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingHandoffBaselinesForClaim(_ items: [PendingHandoffBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveAlertClaimsFromBaseline(_ items: [PendingHandoffBaseline]) -> [AlertClaim] {
        var out: [AlertClaim] = []
        for item in items {
            let derived = newAlertClaim(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyAlertClaim(_ item: AlertClaim) -> Double {
        return pendingHandoffBaselineWeight(7, active: true)
    }
}
