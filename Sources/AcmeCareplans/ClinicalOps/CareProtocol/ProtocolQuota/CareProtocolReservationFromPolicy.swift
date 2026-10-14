import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeWeightedOrderSetPoliciesForReservation(_ items: [WeightedOrderSetPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveCareProtocolReservationsFromPolicy(_ items: [WeightedOrderSetPolicy]) -> [CareProtocolReservation] {
        var out: [CareProtocolReservation] = []
        for item in items {
            let derived = newCareProtocolReservation(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCareProtocolReservation(_ item: CareProtocolReservation) -> String {
        return weightedOrderSetPolicyBucket(item.effectiveTotal())
    }
}
