import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a default formulary override score falls in.
    static func classifyDefaultFormularyOverride(_ score: Double) -> String {
        if score < 56.0 {
            return "elevated"
        }
        if score < 59.5 {
            return "low"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultFormularyOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-formulary-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func defaultFormularyOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
