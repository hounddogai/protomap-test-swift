import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledClosureRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-closure-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled closure request code in its canonical SCR- form.
    static func normalizeScheduledClosureRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCR-") {
            return clean
        }
        return "SCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
