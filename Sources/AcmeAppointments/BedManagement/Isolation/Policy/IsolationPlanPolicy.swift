import AcmePlatform
import Foundation

extension BedManagement {
    static func isolationPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeIsolationPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("isolation-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a isolation plan score falls in.
    static func classifyIsolationPlan(_ score: Double) -> String {
        if score < 18.8 {
            return "elevated"
        }
        if score < 37.2 {
            return "critical"
        }
        if score < 79.4 {
            return "watch"
        }
        return "minimal"
    }

    /// Puts a isolation plan code in its canonical IP- form.
    static func normalizeIsolationPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IP-") {
            return clean
        }
        return "IP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
