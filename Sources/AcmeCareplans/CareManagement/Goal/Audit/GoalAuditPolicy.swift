import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGoalAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("goal-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a goal audit code in its canonical GA- form.
    static func normalizeGoalAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GA-") {
            return clean
        }
        return "GA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
