import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveClosureForecastsForCheckpoint(_ items: [AdaptiveClosureForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRollingSlotCheckpointsFromForecast(_ items: [AdaptiveClosureForecast]) -> [RollingSlotCheckpoint] {
        var out: [RollingSlotCheckpoint] = []
        for item in items {
            let derived = newRollingSlotCheckpoint(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveRollingSlotCheckpoint(_ item: RollingSlotCheckpoint) -> Double {
        return closureReservationWeight(7, active: true)
    }
}
