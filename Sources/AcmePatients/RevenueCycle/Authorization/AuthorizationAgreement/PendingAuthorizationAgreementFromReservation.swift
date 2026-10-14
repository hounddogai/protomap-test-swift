import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceReservationsForAgreement(_ items: [RemittanceReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func derivePendingAuthorizationAgreementsFromReservation(_ items: [RemittanceReservation]) -> [PendingAuthorizationAgreement] {
        var out: [PendingAuthorizationAgreement] = []
        for item in items {
            let derived = newPendingAuthorizationAgreement(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyPendingAuthorizationAgreement(_ item: PendingAuthorizationAgreement) -> String {
        return classifyRemittanceSegment(item.effectiveTotal())
    }
}
