import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftBaselinesForForecast(_ items: [ShiftBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveShiftForecastsFromBaseline(_ items: [ShiftBaseline]) -> [ShiftForecast] {
        var out: [ShiftForecast] = []
        for item in items {
            let derived = newShiftForecast(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyShiftForecast(_ item: ShiftForecast) -> String {
        return classifyShiftBaseline(item.projectedVolume())
    }
}
