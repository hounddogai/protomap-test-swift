import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedShiftTiersForForecast(_ items: [CappedShiftTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePrimaryShiftForecastsFromTier(_ items: [CappedShiftTier]) -> [PrimaryShiftForecast] {
        var out: [PrimaryShiftForecast] = []
        for item in items {
            let derived = newPrimaryShiftForecast(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryShiftForecast(_ item: PrimaryShiftForecast) -> String {
        return rollingShiftManifestBucket(item.measuredValue())
    }
}
