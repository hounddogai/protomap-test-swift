import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftForecastsForWindow(_ items: [ShiftForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveShiftWindowsFromForecast(_ items: [ShiftForecast]) -> [ShiftWindow] {
        var out: [ShiftWindow] = []
        for item in items {
            let derived = newShiftWindow(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeShiftWindow(_ item: ShiftWindow) -> String {
        return classifyAdaptiveShiftBaseline(item.weightedValue())
    }
}
