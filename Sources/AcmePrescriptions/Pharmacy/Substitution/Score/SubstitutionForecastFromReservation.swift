import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyReservationsForForecast(_ items: [FormularyReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveSubstitutionForecastsFromReservation(_ items: [FormularyReservation]) -> [SubstitutionForecast] {
        var out: [SubstitutionForecast] = []
        for item in items {
            let derived = newSubstitutionForecast(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateSubstitutionForecast(_ item: SubstitutionForecast) -> String {
        return normalizeFormularySegmentCode(item.code)
    }
}
