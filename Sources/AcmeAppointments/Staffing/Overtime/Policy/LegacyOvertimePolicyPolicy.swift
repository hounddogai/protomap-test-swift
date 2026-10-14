import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyOvertimePolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-overtime-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a legacy overtime policy code in its canonical LOP- form.
    static func normalizeLegacyOvertimePolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LOP-") {
            return clean
        }
        return "LOP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
