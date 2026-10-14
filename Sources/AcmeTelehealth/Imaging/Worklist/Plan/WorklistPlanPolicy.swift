import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a worklist plan code in its canonical WP- form.
    static func normalizeWorklistPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WP-") {
            return clean
        }
        return "WP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
