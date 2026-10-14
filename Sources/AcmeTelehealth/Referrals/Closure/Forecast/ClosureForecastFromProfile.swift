import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureProfilesForForecast(_ items: [ClosureProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveClosureForecastsFromProfile(_ items: [ClosureProfile]) -> [ClosureForecast] {
        var out: [ClosureForecast] = []
        for item in items {
            let derived = newClosureForecast(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectClosureForecast(_ item: ClosureForecast) -> Double {
        return closureWindowWeight(7, active: true)
    }
}
