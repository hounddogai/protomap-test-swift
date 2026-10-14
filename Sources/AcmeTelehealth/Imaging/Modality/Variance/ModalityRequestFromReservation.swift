import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistReservationsForRequest(_ items: [WorklistReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveModalityRequestsFromReservation(_ items: [WorklistReservation]) -> [ModalityRequest] {
        var out: [ModalityRequest] = []
        for item in items {
            let derived = newModalityRequest(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyModalityRequest(_ item: ModalityRequest) -> String {
        return normalizeWorklistSnapshotCode(item.code)
    }
}
