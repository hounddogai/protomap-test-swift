import AcmePlatform
import Foundation

extension Pharmacy {
    static func fallbackInventoryForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackInventoryForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-inventory-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackInventoryForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
