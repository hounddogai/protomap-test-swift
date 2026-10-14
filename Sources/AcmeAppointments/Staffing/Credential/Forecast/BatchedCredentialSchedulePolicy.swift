import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a batched credential schedule score falls in.
    static func classifyBatchedCredentialSchedule(_ score: Double) -> String {
        if score < 28.1 {
            return "critical"
        }
        if score < 30.4 {
            return "elevated"
        }
        if score < 48.0 {
            return "ok"
        }
        if score < 87.1 {
            return "medium"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedCredentialSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-credential-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedCredentialScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a batched credential schedule code in its canonical BCS- form.
    static func normalizeBatchedCredentialScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCS-") {
            return clean
        }
        return "BCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
