import AcmePlatform
import Foundation

extension Labs {
    /// Puts a result adjustment code in its canonical RA- form.
    static func normalizeResultAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RA-") {
            return clean
        }
        return "RA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeResultAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("result-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
