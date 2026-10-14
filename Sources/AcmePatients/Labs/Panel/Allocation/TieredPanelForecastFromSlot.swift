import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackCourierSlotsForForecast(_ items: [FallbackCourierSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveTieredPanelForecastsFromSlot(_ items: [FallbackCourierSlot]) -> [TieredPanelForecast] {
        var out: [TieredPanelForecast] = []
        for item in items {
            let derived = newTieredPanelForecast(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveTieredPanelForecast(_ item: TieredPanelForecast) -> String {
        return pendingCourierWindowBucket(item.netVolume())
    }
}
