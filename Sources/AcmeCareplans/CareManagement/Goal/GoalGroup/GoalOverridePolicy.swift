import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGoalOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("goal-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a goal override code in its canonical GO- form.
    static func normalizeGoalOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GO-") {
            return clean
        }
        return "GO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
