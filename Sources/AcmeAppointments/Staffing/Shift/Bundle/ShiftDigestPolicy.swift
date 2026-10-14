import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a shift digest code in its canonical SD- form.
    static func normalizeShiftDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SD-") {
            return clean
        }
        return "SD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeShiftDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("shift-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
