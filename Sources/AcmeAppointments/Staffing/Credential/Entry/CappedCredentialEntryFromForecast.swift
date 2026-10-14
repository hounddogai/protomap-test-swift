import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeDefaultShiftForecastsForEntry(_ items: [DefaultShiftForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedCredentialEntriesFromForecast(_ items: [DefaultShiftForecast]) -> [CappedCredentialEntry] {
        var out: [CappedCredentialEntry] = []
        for item in items {
            let derived = newCappedCredentialEntry(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectCappedCredentialEntry(_ item: CappedCredentialEntry) -> String {
        return normalizeDefaultShiftReservationCode(item.code)
    }
}
