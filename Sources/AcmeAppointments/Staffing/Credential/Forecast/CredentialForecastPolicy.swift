import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a credential forecast score falls in.
    static func classifyCredentialForecast(_ score: Double) -> String {
        if score < 26.1 {
            return "elevated"
        }
        if score < 54.6 {
            return "low"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCredentialForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("credential-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeCredentialForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
