import AcmePlatform
import Foundation

extension Imaging {
    static func fallbackCareProtocolWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackCareProtocolWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-care-protocol-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback care protocol window score falls in.
    static func classifyFallbackCareProtocolWindow(_ score: Double) -> String {
        if score < 18.2 {
            return "ok"
        }
        if score < 33.8 {
            return "medium"
        }
        if score < 84.7 {
            return "high"
        }
        return "low"
    }

    static func fallbackCareProtocolWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
