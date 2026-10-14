import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a primary worklist milestone code in its canonical PWM- form.
    static func normalizePrimaryWorklistMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PWM-") {
            return clean
        }
        return "PWM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryWorklistMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-worklist-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
