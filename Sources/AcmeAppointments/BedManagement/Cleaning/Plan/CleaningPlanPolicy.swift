import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCleaningPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("cleaning-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cleaningPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a cleaning plan score falls in.
    static func classifyCleaningPlan(_ score: Double) -> String {
        if score < 33.2 {
            return "critical"
        }
        if score < 67.3 {
            return "high"
        }
        if score < 93.6 {
            return "medium"
        }
        if score < 96.7 {
            return "minimal"
        }
        return "ok"
    }

    /// Puts a cleaning plan code in its canonical CP- form.
    static func normalizeCleaningPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CP-") {
            return clean
        }
        return "CP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
