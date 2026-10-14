import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyOrderSetReservationsForEntry(_ items: [LegacyOrderSetReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultAlertEntriesFromReservation(_ items: [LegacyOrderSetReservation]) -> [DefaultAlertEntry] {
        var out: [DefaultAlertEntry] = []
        for item in items {
            let derived = newDefaultAlertEntry(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceDefaultAlertEntry(_ item: DefaultAlertEntry) -> String {
        return normalizeLegacyOrderSetReservationCode(item.code)
    }
}
