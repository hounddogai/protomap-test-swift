import AcmePlatform
import Foundation

extension RevenueCycle {
    static func seasonalDenialForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a seasonal denial forecast code in its canonical SDF- form.
    static func normalizeSeasonalDenialForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SDF-") {
            return clean
        }
        return "SDF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalDenialForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalDenialForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-denial-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
