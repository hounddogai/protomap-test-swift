import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedClaimReservationsForBudget(_ items: [CappedClaimReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDenialBudgetsFromReservation(_ items: [CappedClaimReservation]) -> [DenialBudget] {
        var out: [DenialBudget] = []
        for item in items {
            let derived = newDenialBudget(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyDenialBudget(_ item: DenialBudget) -> String {
        return rollingClaimEstimateBucket(item.effectiveTotal())
    }
}
