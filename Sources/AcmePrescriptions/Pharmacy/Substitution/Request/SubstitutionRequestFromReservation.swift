import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePendingFormularyReservationsForRequest(_ items: [PendingFormularyReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveSubstitutionRequestsFromReservation(_ items: [PendingFormularyReservation]) -> [SubstitutionRequest] {
        var out: [SubstitutionRequest] = []
        for item in items {
            let derived = newSubstitutionRequest(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreSubstitutionRequest(_ item: SubstitutionRequest) -> String {
        return normalizeFormularyScheduleCode(item.code)
    }
}
