import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialReservationsForEstimate(_ items: [CredentialReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveAdaptiveAcuityPlanEstimatesFromReservation(_ items: [CredentialReservation]) -> [AdaptiveAcuityPlanEstimate] {
        var out: [AdaptiveAcuityPlanEstimate] = []
        for item in items {
            let derived = newAdaptiveAcuityPlanEstimate(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeAdaptiveAcuityPlanEstimate(_ item: AdaptiveAcuityPlanEstimate) -> Double {
        return credentialReservationWeight(4, active: true)
    }
}
