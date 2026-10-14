import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferOverridesForForecast(_ items: [TransferOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveIsolationForecastsFromOverride(_ items: [TransferOverride]) -> [IsolationForecast] {
        var out: [IsolationForecast] = []
        for item in items {
            let derived = newIsolationForecast(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreIsolationForecast(_ item: IsolationForecast) -> String {
        return transferScheduleBucket(item.measuredValue())
    }
}
